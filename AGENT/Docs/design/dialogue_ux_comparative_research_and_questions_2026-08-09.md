---
Type: design
Status: Research packet — discussion OPEN
Last verified: 2026-08-09
Tracker: DISCUSS-DIALOGUE-UX-2026-07-23
Question set: DLUX-1..16
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md) (`B4-DIALOGUE-V1`)
---

# Dialogue UX — Comparative Research, Boundaries, and Owner Questions

**Managed by:** [Project Control Plane](../plans/project_control_plane_2026-06-29.md),
`B4-DIALOGUE-V1`.

## 1. Purpose

This packet asks what player and author problems a Prometheus dialogue system must solve before it
chooses a renderer, file format, or editor. It compares older *Fire Emblem*, Fire Emblem ROM-hacking
tools, SRPG Studio, and adjacent narrative/event tools as evidence. None is a blueprint.

The earlier `[DLG]` and `[DRC]` work contains useful contracts, but it also combines a large stage,
chat log, branching, effects, Talk, recruitment, custody, and transactional actions in one portfolio.
This pass deliberately separates those concerns and tests whether each proposed feature fills a real
hole. It does **not** reopen the five-dimensional unit-state or custody decisions unless a dialogue
boundary contradicts them.

## 2. The holes to fill

Prometheus currently has no conversation catalogue, dialogue runner, presenter, Talk interaction, or
dialogue authoring tool. The only production-code trace is the reserved
`SaveData.conversation_resume = null`. Therefore the actual holes are:

1. **Readable delivery:** present authored lines, speakers, choices, and optional visual cues with
   controller, keyboard, mouse, touch, localization, history, and accessibility support.
2. **Deterministic traversal:** select the next addressable entry from immutable conversation data,
   local branch state, and read-only shared facts.
3. **Safe composition:** request gameplay consequences through their owning action services without
   making dialogue the authority for recruitment, inventory, relationships, maps, or custody.
4. **Discoverable invocation:** let map Talk, story events, supports, base/camp scenes, tutorials, and
   barks invoke a conversation without becoming different interpreters.
5. **Low-code authoring:** let an author write, validate, preview, localize, and diff a conversation
   without learning engine internals or managing anonymous numeric flags.
6. **Failure visibility:** report missing speakers, text, assets, targets, requirements, commands, and
   unreachable branches before a player finds them.

These are separate holes. A cinematic stage does not solve event traversal. A node graph does not
solve controller UX. A command list does not own game state merely because it can request a change.

## 3. Explicit non-goals

The dialogue system is **not**:

- a general map-event engine, quest engine, cutscene compositor, animation package, or save system;
- the owner of recruitment, affiliation, controller, roster, relationship, inventory, objective, or
  custody state;
- a second requirement language or a bag of private dialogue flags;
- a universal full-screen presentation forced onto barks, Talk, supports, and story scenes alike;
- a visual-programming environment for arbitrary game logic;
- a promise that every effect seen in a reference game belongs in V1.

Dialogue may call those systems through typed ports. It must not absorb them.

## 4. Comparative evidence

### 4.1 Older Fire Emblem: several conversation products, not one UX

The oldest official manual used here, *Shadow Dragon & the Blade of Light*, describes a tight
move-then-one-action tactical loop and chapter structure. It is evidence for Talk as a contextual map
action with an activation cost, not evidence for a general narrative runtime
([Nintendo manual](https://csassets.nintendo.com/noaext/image/private/t_KA_PDF/FESD_BL_NES_eManual_ENG?_a=DATC1RAAZAA0)).

The GBA games use compact portrait-and-text scenes for chapter story, contextual battlefield Talk,
and adjacent support conversations. Their strength is legibility and low interaction cost. Their
limitations are equally important: Talk eligibility can be opaque; support discovery and grinding
can obscure authored character material; presentation is mostly linear; and the format reflects GBA
memory and screen constraints. The official Japanese *Blazing Blade* manual is retained as primary
period evidence, while exact authoring behavior is better exposed by the ROM tools below
([Nintendo manual](https://www.nintendo.co.jp/data/software/manual/manual_PAZJ_00.pdf)).

*Path of Radiance* moves support and base conversations out of tactical positioning and into a base
surface. This is a product-level lesson: availability, discovery, chronology, and reward policy
belong to the **invoking feature**, while the content can still use a shared line/choice runner. A
support conversation is not a battlefield Talk merely because both show portraits and text.

**Boundary lesson:** older FE supplies several proven invocation profiles—chapter story, Talk,
support, base information, and short reactive lines. It does not justify one mandatory full-screen
stage or putting support progression inside the dialogue runner.

### 4.2 FEBuilderGBA: make ROM structures discoverable, but do not inherit them

[FEBuilderGBA](https://github.com/FEBuilderGBA/FEBuilderGBA) succeeds by giving authors searchable,
specialized editors over a fixed GBA ROM: text and portrait editing, event lists, Talk conditions,
flags, previews, and patches live close to the data they affect. Common FE work is discoverable
without asking authors to remember raw addresses or opcodes.

The productive lesson is the focused workflow: a Talk form should name actor, target, eligibility,
completion policy, conversation, and action cost; a conversation editor should show speakers and
lines in context; validation should link to the bad field. The dangerous lesson would be to reproduce
ROM-era coupling—numeric flags, fixed tables, engine-version-specific opcodes, and edits whose meaning
depends on hidden binary layout.

**Boundary lesson:** borrow contextual forms, lookup pickers, validation, and preview. Do not make
Prometheus campaign authors understand storage layout, global flag numbers, or engine opcodes.

### 4.3 Event Assembler: powerful compiled commands are infrastructure, not UX

The [Event Assembler standard library](https://github.com/StanHash/EAStandardLibrary/blob/master/EAstdlib.event)
shows why a stable command vocabulary, macros, labels, and compilation are effective for expert ROM
authors. It also shows why the low-level representation should not be the only authoring surface:
large command scripts expose engine sequencing and state details, and safe composition depends on
the author knowing which macro mutates what.

Prometheus can keep a validated, addressable compiled entry stream without presenting that stream as
the only writing experience. High-level Talk/support/story templates may compile to the same data.
Game effects remain calls to registered action handlers with declared schemas and authority.

**Boundary lesson:** a compiler target is valuable; an opcode language is not automatically a good
dialogue editor or a license for arbitrary state mutation.

### 4.4 SRPG Studio: domain events and extensibility, with visible coupling costs

SRPG Studio separates event categories such as map Talk, communication/base events, recollection,
and general event-command lists. Its message commands support control codes and runtime variables,
and its plugin ecosystem adds layouts and commands. This is evidence that authors benefit from
domain-specific entry points over a reusable event-command substrate. The official help is at
[SRPG Studio Help](https://srpgstudio.com/english/help/index.html); a community tutorial usefully
summarizes the product's distinct conversation, communication, common, and recollection event types
([Game Creation Lab tutorial](https://game-sakusei.com/srpg_studio/7823.html)).

Its tradeoff is coupling through a broad event vocabulary and embedded control codes. A message can
become responsible for layout, pacing, substitution, and state lookup in one string; plugins may add
capability without a campaign-level schema or portability guarantee.

**Boundary lesson:** keep invocation profiles and extensible commands, but use typed cue data and
typed text substitutions rather than an ever-growing escape-code language.

### 4.5 RPG Maker: approachable ordered lists, easy hidden-state debt

RPG Maker MZ puts Show Text, Show Choices, switches, variables, conditional branches, common events,
labels, and party mutations into one ordered event-command list
([official command reference](https://rpgmakerofficial.com/product/MZ_help-en/01_10.html)). This makes
small scenes easy and is strong evidence for an ordered authoring view.

It also demonstrates the risk of stretching that view into the state architecture: arbitrary
switches, variables, labels, and direct party mutations can make ownership and consequences hard to
audit. Prometheus should show game actions in the sequence, but those entries must validate and
dispatch through the action's owning system.

**Boundary lesson:** adopt the readable sequence and reusable common blocks; reject anonymous shared
state and unrestricted mutation.

### 4.6 Ren'Py and Yarn Spinner: learn from narrative runtimes without becoming one

Ren'Py treats dialogue statements, menus, history, save state, and rollback as a coherent visual-
novel runtime. Its documentation explains that saves/checkpoints occur at statement interaction
boundaries and that custom interactions must participate deliberately in rollback
([official save/rollback documentation](https://www.renpy.org/doc/html/save_load_rollback.html)). That
supports stable dialogue addresses and explicit consequence boundaries. It does **not** prove that a
tactical RPG should serialize its entire presentation stack or offer VN-style rollback across map
state.

Yarn Spinner separates authored script, dialogue traversal, variable storage, line delivery, views,
and registered commands. It is strong evidence for ports between runner, state, presentation, and
gameplay. It remains a reference rather than a dependency: Prometheus has pack validation,
deterministic tactical state, action journals, and open registry obligations that a general narrative
tool does not own ([Yarn Spinner documentation](https://docs.yarnspinner.dev/)).

**Boundary lesson:** borrow separation and testable traversal. Do not import a general narrative
engine's save model, variable store, or rendering assumptions wholesale.

## 5. What each reference is actually good for

| Reference | Hole it helps fill | Do not stretch it into |
|---|---|---|
| Older FE map Talk | Contextual invocation, concise battlefield delivery, action cost | General event runner or all dialogue presentation |
| GBA supports | Pair-specific progression delivery and compact scenes | Relationship authority or universal adjacency policy |
| Path of Radiance base conversations | Discoverable between-map optional information | A requirement that all optional dialogue live in Prep |
| FEBuilderGBA | Focused editors, pickers, previews, diagnostics | ROM tables, numeric flags, or fixed engine vocabulary |
| Event Assembler | Stable compiled commands, macros, labels | Default low-code UX or unrestricted mutation |
| SRPG Studio | Domain event profiles plus reusable commands/plugins | Escape-code-heavy strings or plugin-defined save truth |
| RPG Maker | Readable ordered authoring and reusable common events | Anonymous global switches and one omnipotent interpreter |
| Ren'Py | History, input, checkpoints, rollback semantics | VN-style full-state rollback in tactical play |
| Yarn Spinner | Runner/view/state/command separation | A second authoritative state store |

## 6. Recommended composable shape

```text
invoker (Talk / MET / support / Prep / bark)
    -> ConversationRequest {conversation_id, profile_id, bound roles, context}
    -> ConversationCatalogue (immutable validated data)
    -> ConversationRunner (pure traversal + ephemeral locals)
       -> RequirementPort (read-only shared facts)
       -> PresentationCuePort (cosmetic, replayable/skippable metadata)
       -> GameActionPort (typed requests; owning service validates/stages/commits)
    -> Presenter selected by profile and current responsive layout
       -> input / text / portraits / stage / choices / history / accessibility
    -> ConversationResult (completed / cancelled / failed + choices + action results)
    -> invoker owns aftermath and action cost
```

Rules:

- The runner never looks up map nodes, mutates units, awards items, or advances supports directly.
- Presenters never decide branches or game consequences.
- Invokers decide eligibility, disclosure, action cost, and what completion means for their domain.
- Requirements read owning-system facts through typed subjects; dialogue does not mirror them.
- Presentation cues and game actions use different open registries and metadata contracts.
- Profiles are data/policy bundles, not subclasses or closed engine enums.
- A basic textbox presenter must be sufficient for every valid conversation. Rich stage cues are
  optional enhancement; missing optional art must degrade, not invalidate prose.
- Skip changes time spent, never chosen branches or consequences. Replay suppresses game actions.
- V1 may restart an atomic conversation from the preceding committed checkpoint, as DRC decided;
  post-V1 checkpoints need an explicit contract and must not emerge accidentally from line indexes.

## 7. Pressure against the existing design

1. **One mandatory stage-over-chat-log overlay is too broad.** Keep it as a possible rich presenter,
   not the definition of dialogue. It does not fit barks, terse map Talk, or every screen size.
2. **Reflect, scene-wide filters, arbitrary-angle transforms, and live compositing are cutscene-stage
   features.** They may be presentation cues or a later stage module; they are not prerequisites for
   readable dialogue V1.
3. **A conversation can contain game-action requests, but it is not a transaction engine.** The
   general action journal owns atomicity and overlay reads.
4. **Talk, support, and recruitment are invokers/consumers.** Talk owns spatial/action policy;
   support owns progression; recruitment owns unit transitions.
5. **A dedicated graph editor is not the first authoring requirement.** A sequence outline, focused
   forms, stable IDs, search, validation, and preview solve the immediate author hole with less
   machinery. A graph view can be added when branching scale proves the need.

## 8. Owner questions

### [DLUX-1] What is the V1 presentation floor?

- **A:** compact speaker name, text, optional portrait, choices, history, and control hints.
- **B:** the full stage-over-chat-log design.
- **Recommendation:** A. Reserve B as a rich profile/presenter so V1 does not wait on a cutscene
  compositor.

**Owner ruling, 2026-08-09:** **A approved.** V1 requires the compact floor: speaker name, text,
optional portrait, choices, history, and control hints. The rich stage is not a V1 validity or
delivery requirement.

### [DLUX-2] Is the stage-over-chat-log layout mandatory or profile-selected?

- **A:** mandatory for every conversation.
- **B:** one presenter/layout selected by profile and responsive context.
- **Recommendation:** B.

**Owner ruling, 2026-08-09:** **B approved.** Stage-over-chat-log is an optional presenter/layout
selected through profile policy and responsive context. It is not the definition of a conversation,
and content that uses only the compact presenter remains first-class.

### [DLUX-3] Which invocation profiles ship in V1?

- Suggested minimum: `story`, `map_talk`, `support`, `bark`; `base_info` can reuse `story` until Prep
  needs distinct discovery policy.
- **Recommendation:** ship only profiles with a real first consumer; profiles configure policy and
  defaults, not separate runners.

**Owner ruling, 2026-08-09:** approve `story`, `map_talk`, `support`, and `bark` as the primary V1
dialogue consumers. `base_info` initially reuses `story` and becomes a distinct profile only when a
real base browser needs different discovery, importance, availability, or replay policy. Villages,
recruitment, Prison, tutorials, and later features do not gain profiles merely because they contain
dialogue: they invoke the closest existing profile and keep their domain policy in their owning
system. Profiles remain registered data-policy bundles over one runner, not subclasses or a closed
engine enum.

### [DLUX-4] Does a bark enter the conversation runner?

- **A:** yes, if it needs localization, speaker identity, history/visibility policy, and sequencing.
- **B:** no, use a notification/callout system for non-blocking one-shot combat feedback.
- **Recommendation:** distinguish blocking narrative barks (A) from combat notifications (B). Do not
  make the dialogue presenter the combat-feedback system.

**Owner ruling, 2026-08-09:** approve the boundary. A blocking authored narrative bark may use the
dialogue runner. Non-blocking mechanical feedback—including skill activation, critical, immunity,
status, and resolution callouts—belongs exclusively to the existing combat-notification system and
must not be duplicated in dialogue. One combat event may independently emit a mechanical
notification and invoke an authored narrative bark when both are warranted; neither channel proxies
for the other, and only the narrative bark enters dialogue history.

### [DLUX-5] What does History contain?

- Candidate: completed player-visible lines and chosen option labels, with speaker and conversation
  identity; exclude hidden commands and debug details.
- **Recommendation:** history is presenter/session output, not the action journal and not durable
  campaign state. Decide separately whether a conversation archive is a campaign feature.

**Owner ruling, 2026-08-09 — replace the local-history recommendation with the existing unified
chapter log:** V1 integrates dialogue history, the combat log, and Rewind into one on-demand chapter
log menu. This confirms the seam already ratified by `[CFB-3]` in
[`combat_feedback_vocabulary_open_questions_2026-08-07.md`](../registers/combat_feedback_vocabulary_open_questions_2026-08-07.md):

- `MapLedger` remains the sole checkpoint/restore authority. The combined menu consumes its retained
  round/activation blocks; it does not create a second timeline or Rewind implementation.
- Player-visible combat-event records and dialogue records render inside/between those blocks in
  chapter order. Dialogue records contain completed lines, speaker identity, conversation identity,
  and chosen option labels—not hidden requirements, commands, action-journal internals, or duplicate
  combat notifications.
- A log position is a Rewind target only when it is anchored to a retained ledger checkpoint and
  `GameState` reports that the target is affordable with the current Rewind budget. Narrative lines
  and combat records are explanatory content, not independent restore points.
- The menu clearly distinguishes review-only history, an unavailable/pruned checkpoint, and an
  available checkpoint with its charge cost. Rewind availability and cost are never inferred by the
  dialogue or log presenter.
- The combined log is chapter-scoped. A persistent cross-chapter conversation gallery/archive, if
  later wanted, remains a separate campaign-library feature with its own spoiler/unlock policy.
- This is composition, not duplication: combat owns combat-event records, dialogue owns dialogue
  records, `MapLedger` owns restore points, and one presenter interleaves their public projections.

**Follow-up needed:** after a Rewind, decide whether future records are removed from the active log
or retained as an explicitly abandoned timeline. Recommendation for V1: truncate the active log at
the restored checkpoint alongside `MapLedger`; replayed actions then append a new canonical future.
Do not build alternate-timeline browsing without a separate use case.

**Owner ruling, 2026-08-09:** approve truncation. V1 has one canonical active chapter timeline. A
successful Rewind atomically truncates later retained checkpoints and their anchored combat/dialogue
public records; replayed actions append the replacement future. There is no abandoned-timeline
archive or branch browser in V1. If explanatory records are retained more broadly than restorable
snapshots, their checkpoint anchors must still participate in this same truncation boundary.

### [DLUX-6] What is Auto mode?

- **Recommendation:** a player pacing preference advancing only after text completion plus a bounded
  reading delay/voice completion. It always stops at choices, errors, focus loss, and explicit waits.
  It never grants command authority.

**Owner ruling, 2026-08-09:** Auto remains available for every conversation and profile; neither a
profile nor campaign content may disable the player affordance. Auto advances only after text
completion plus the player-configured bounded reading delay (or later voice completion), and pauses
at choices, errors, focus loss, another opened menu, and explicit authored waits. Those pauses
request attention without turning Auto off. Auto controls pacing only and never selects a choice or
grants game-action authority.

### [DLUX-7] What is Skip mode?

- **Recommendation:** accelerate/suppress presentation while traversing the identical runner path;
  stop at unresolved choices. Never skip game-action requests or requirement evaluation.

**Owner ruling, 2026-08-09:** Skip is universally available for every conversation and profile,
including first viewing; campaign content may not disable it. Skip accelerates or suppresses
presentation while traversing the identical authoritative runner path. It evaluates every
requirement, stages every game-action request, stops at unresolved choices and errors, and cannot
jump to an authored approximation of the ending or otherwise alter outcomes.

### [DLUX-8] Can the player cancel a conversation?

- Options: never; only before any staged action; or profile policy with a structured confirmation.
- **Recommendation:** story/Talk/support are non-cancellable after start in V1; replay is freely
  cancellable because actions are suppressed. Avoid pretending rollback exists.

**Owner ruling, 2026-08-09:** approve the boundary. A live `story`, `map_talk`, or `support`
conversation cannot be player-cancelled after it starts; it completes or fails atomically. Universal
Skip is the player-controlled fast path through unwanted live text without inventing trigger replay,
action-cost refunds, partial journal commits, or rollback semantics. Replay/archive playback is
freely cancellable because game actions are suppressed. A runtime or validation error aborts and
discards the staged journal safely; that is failure handling, not player cancellation.

### [DLUX-9] How are unavailable choices shown?

- **Recommendation:** reuse shared requirement disclosure (`hidden`, `shown_disabled` with localized
  unmet reason). Dialogue owns layout only, not truth or reason wording.

**Owner ruling, 2026-08-09:** approve author-selectable `shown_disabled|hidden` per option, with
`shown_disabled` as the default. A shown disabled choice includes the shared Requirement system's
localized unmet reason. `hidden` is reserved for authored secrets or undiscovered branches, not used
as the general failure presentation. Dialogue owns layout and focus behavior only; Requirement owns
eligibility, disclosure result, and reason data.

### [DLUX-10] Are presentation cues required for validity?

- **Recommendation:** prose, speaker/text identity, and choice structure are required. Portrait,
  animation, stage, audio, and effects declare `required|optional`; optional failures use a stable
  fallback and structured warning.

**Owner ruling, 2026-08-09:** approve prose-first validity with explicit escalation. Conversation
structure, speaker/text identity, choice structure, requirements, and game-action requests are
required. Portraits, backgrounds, animation, audio, and stage effects default to `optional`; a
missing optional asset uses the registered stable fallback and emits a structured warning. An author
may mark an individual presentation asset `required` when the scene cannot communicate correctly
without it, in which case pack validation fails before play. A profile cannot silently make an
entire media category required.

### [DLUX-11] What is the first authoring surface?

- **A:** raw canonical JSON.
- **B:** ordered outline editor with focused line/choice/cue/action forms and live preview.
- **C:** arbitrary node graph.
- **Recommendation:** B, exporting canonical JSON; retain supported hand-editing and schema tools.

**Owner ruling, 2026-08-09:** approve **B**, an ordered outline editor with focused validated forms,
stable-ID branch navigation, live disposable-state preview, and canonical diffable JSON export.
Supported hand-edited JSON remains a first-class input to the same validator.

**Special editor reservation — demand-gated node/state-machine graph view:** retain a graph view as a
deliberate future option if real authoring evidence shows that large branching conversations are
unmanageable in the outline. It must be an alternate projection/editor over the same canonical
conversation data and stable IDs—not a second source format, separate runtime, or graph-owned state
machine. Before it ships, prove lossless outline/graph/JSON round-tripping, deterministic layout or
layout metadata that does not affect runtime meaning, usable keyboard/controller navigation, and a
measured conversation corpus whose branch depth/edge density demonstrates the need. Demand is the
gate; the reservation is not permission to build graph infrastructure speculatively.

### [DLUX-12] How much game logic may the dialogue editor expose?

- **Recommendation:** typed requirement selectors and registered game-action forms only. No arbitrary
  GDScript, anonymous global variables, or raw mutation expressions in campaign data.

**Owner ruling, 2026-08-09:** approve the authority boundary. The editor exposes typed shared-
Requirement selectors, registered game-action forms, presentation cues, and conversation-local
branching/ephemeral variables. It does not expose arbitrary GDScript, raw property mutation,
anonymous global variables, or unrestricted expressions in campaign dialogue. Initial form families
may include fact writes, permanent/guest unit transitions, item/resource transfer, relationship
changes, registered conditions, objective milestones, occupancy-safe move/spawn, conversation unlock,
registered activity launch, and campaign-flow transition. Each form is generated from the owning
action registry's schema and emits a typed request; the owning service validates, previews,
stages/commits, reports structured failure, logs, and participates in save/Rewind. Adding capability
means registering a schema-described handler with its domain owner, never adding dialogue-specific
direct-write code.

### [DLUX-13] How are reusable fragments handled?

- Options: duplicate; textual include/macro; call another conversation and return.
- **Recommendation:** no general call stack in V1. Permit editor templates for authoring-time
  expansion and separate conversations for genuinely independent scenes. Add runtime calls only
  after a concrete reuse case defines role binding, local scope, history, and failure behavior.

**Owner ruling, 2026-08-09:** approve authoring-time templates/copy expansion only for V1. Applying a
template creates ordinary independent conversation entries with fresh stable IDs; the copy does not
inherit from, load, or otherwise depend on the original template and remains valid if that template
is changed or removed. The editor may retain non-authoritative template-origin provenance for human
reference, but it has no runtime meaning. Multiple invokers may still reference the same independent
conversation ID with validated role bindings and invocation context. What V1 omits is one
conversation calling another from inside its entry stream; add that only after a concrete reuse case
defines role binding, local scope, return/history identity, skip/failure behavior, recursion limits,
and save compatibility.

### [DLUX-14] What is the localization source of truth?

- **Recommendation:** stable line IDs with readable source-language text in the authoring view;
  deterministic export to localization tables; substitutions are typed tokens resolved through
  owning systems. Do not make prose unreadable by requiring authors to work only in a second file.

**Owner ruling, 2026-08-09:** approve stable line IDs plus readable source-language text and typed
substitutions. Export deterministically generates localization tables keyed by line ID, never by
array position or current prose; editing source text flags translations for review without changing
identity. Conversation roles bind stable entity IDs, while typed tokens resolve display names,
pronouns/titles, items, amounts, locations, and other dynamic values through their owning data
systems. A character rename therefore propagates everywhere without rewriting dialogue or changing
translation keys. The validator rejects unknown token types, missing role bindings, and invalid
entity references before play, and translator context records each token's type/role so languages
can place and inflect it correctly. Avoid string concatenation as a localization mechanism.

### [DLUX-15] What should preview simulate?

- **Recommendation:** presenter/layout, traversal, roles, substitutions, requirements, choices, and
  proposed action results against a disposable fixture. Preview never commits campaign state.

### [DLUX-16] Which rich-stage features remain in the dialogue scope?

- Candidate cues: portrait enter/exit/expression/position, background, music/SFX request, simple
  transition. Reflection, arbitrary transforms, scene-wide filters, and animated non-speaker stage
  entities belong to a later cutscene-stage module unless a concrete V1 scene requires them.
- **Recommendation:** accept the candidate cue floor and move the rest behind an optional stage port.

## 9. Proposed V1 acceptance boundary

A V1 conversation is complete when an author can create canonical pack data with stable IDs; bind
roles; write localized lines and choices; select typed requirements, cues, and game-action requests;
validate and preview it; invoke it from story, map Talk, support, or a blocking bark; operate it with
all supported input modes; use manual/auto/skip/history; and receive deterministic completion or
failure without the presenter owning game state.

V1 does **not** require reflection, arbitrary stage transforms, a general graph editor, runtime
subroutine calls, mid-conversation persistence, voice acting, lip sync, a conversation archive, or a
general-purpose event language.

## 10. Reference quality and limits

- Nintendo manuals are primary evidence for player-facing period behavior, but manuals do not expose
  internal data architecture.
- FEBuilderGBA and Event Assembler repositories are primary evidence for their tools. Community guides
  are used only where tool workflows are not documented upstream and are labeled as such.
- SRPG Studio's official English help establishes the product surface; the linked tutorial is a
  secondary description of event categories.
- Ren'Py, Yarn Spinner, and RPG Maker official documentation establishes their contracts. Their
  architecture is evidence, not an implicit dependency recommendation.
