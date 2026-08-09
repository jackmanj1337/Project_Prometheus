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

### [DLUX-2] Is the stage-over-chat-log layout mandatory or profile-selected?

- **A:** mandatory for every conversation.
- **B:** one presenter/layout selected by profile and responsive context.
- **Recommendation:** B.

### [DLUX-3] Which invocation profiles ship in V1?

- Suggested minimum: `story`, `map_talk`, `support`, `bark`; `base_info` can reuse `story` until Prep
  needs distinct discovery policy.
- **Recommendation:** ship only profiles with a real first consumer; profiles configure policy and
  defaults, not separate runners.

### [DLUX-4] Does a bark enter the conversation runner?

- **A:** yes, if it needs localization, speaker identity, history/visibility policy, and sequencing.
- **B:** no, use a notification/callout system for non-blocking one-shot combat feedback.
- **Recommendation:** distinguish blocking narrative barks (A) from combat notifications (B). Do not
  make the dialogue presenter the combat-feedback system.

### [DLUX-5] What does History contain?

- Candidate: completed player-visible lines and chosen option labels, with speaker and conversation
  identity; exclude hidden commands and debug details.
- **Recommendation:** history is presenter/session output, not the action journal and not durable
  campaign state. Decide separately whether a conversation archive is a campaign feature.

### [DLUX-6] What is Auto mode?

- **Recommendation:** a player pacing preference advancing only after text completion plus a bounded
  reading delay/voice completion. It always stops at choices, errors, focus loss, and explicit waits.
  It never grants command authority.

### [DLUX-7] What is Skip mode?

- **Recommendation:** accelerate/suppress presentation while traversing the identical runner path;
  stop at unresolved choices. Never skip game-action requests or requirement evaluation.

### [DLUX-8] Can the player cancel a conversation?

- Options: never; only before any staged action; or profile policy with a structured confirmation.
- **Recommendation:** story/Talk/support are non-cancellable after start in V1; replay is freely
  cancellable because actions are suppressed. Avoid pretending rollback exists.

### [DLUX-9] How are unavailable choices shown?

- **Recommendation:** reuse shared requirement disclosure (`hidden`, `shown_disabled` with localized
  unmet reason). Dialogue owns layout only, not truth or reason wording.

### [DLUX-10] Are presentation cues required for validity?

- **Recommendation:** prose, speaker/text identity, and choice structure are required. Portrait,
  animation, stage, audio, and effects declare `required|optional`; optional failures use a stable
  fallback and structured warning.

### [DLUX-11] What is the first authoring surface?

- **A:** raw canonical JSON.
- **B:** ordered outline editor with focused line/choice/cue/action forms and live preview.
- **C:** arbitrary node graph.
- **Recommendation:** B, exporting canonical JSON; retain supported hand-editing and schema tools.

### [DLUX-12] How much game logic may the dialogue editor expose?

- **Recommendation:** typed requirement selectors and registered game-action forms only. No arbitrary
  GDScript, anonymous global variables, or raw mutation expressions in campaign data.

### [DLUX-13] How are reusable fragments handled?

- Options: duplicate; textual include/macro; call another conversation and return.
- **Recommendation:** no general call stack in V1. Permit editor templates for authoring-time
  expansion and separate conversations for genuinely independent scenes. Add runtime calls only
  after a concrete reuse case defines role binding, local scope, history, and failure behavior.

### [DLUX-14] What is the localization source of truth?

- **Recommendation:** stable line IDs with readable source-language text in the authoring view;
  deterministic export to localization tables; substitutions are typed tokens resolved through
  owning systems. Do not make prose unreadable by requiring authors to work only in a second file.

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
