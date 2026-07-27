---
Type: register
Status: OPEN
Last verified: 2026-07-27
Register: DRC-1..33
---

# Dialogue, Recruitment, and Capture — Research and Implementation-Planning Questions

**Purpose:** identify every owner decision needed before writing an implementation plan for
dialogue, recruitment, and prisoner capture. This is a research and questions packet, not an
implementation plan. Here, **dialogue** includes map conversations, supports, base/camp scenes,
cutscenes, and choices; **capture** means taking a unit the player does not control into custody;
**recruitment** means changing a unit's controlling faction, temporarily or permanently.

## Executive finding

The existing design has a strong reusable center: an event runner invokes a conversation by stable
ID; a conversation is an addressable sequence of lines, choices, labels, and registered commands;
requirements and consequences use shared predicates/actions; presentation is separate from game
state. Keep that center.

Three earlier assumptions must be reopened because they conflict with the definitions above:

1. `[RCR-1]` makes recruitment a player-faction flip **and** permanent roster insertion. That cannot
   express a guest controlled for three turns, a charmed enemy, a story loan, or a unit who changes
   sides but does not join the campaign roster.
2. `[RCR-5]` says a captured enemy's roster end-state is recruitable. Custody and allegiance are
   independent outcomes; release, exchange, ransom, interrogation, trial, escape, and execution must
   not require a recruitment state.
3. `Unit.team` is currently expected to stand for diplomatic faction, controller, AI behavior, turn
   ownership, and roster membership. Those often coincide, but temporary recruitment and custody
   make the differences observable.

**Provisional architectural recommendation:** one conversation runner and one shared event
command/predicate vocabulary, with multiple authored **conversation profiles** (map talk, support,
story scene, base scene) and swappable presenters. Separately model unit identity, affiliation,
controller, roster membership, and custody. Treat recruit and capture as registered state-transition
actions that can be invoked by dialogue or by any other event; neither should be embedded in the
dialogue interpreter.

## Research synthesis

### Player perspective

- Classic Fire Emblem recruitment often makes positioning and character knowledge part of the map
  puzzle: a specific actor uses Talk on a specific adjacent unit. That produces memorable stories,
  but opaque eligibility can push players toward external guides. The FEBuilder event editor exposes
  Talk Conditions as a distinct chapter-event category with initiator, target, event, and completion
  flag, accurately reflecting that model ([FEBuilder event-editor FAQ](https://feuniverse.us/t/ultraxblades-febuilder-help-faq/19565?page=2)).
- *Thracia 776* makes capture a risky tactical/economic action tied to carrying and inventory
  seizure. Nintendo's own description highlights both capturing enemies to take items and carrying
  allies as new strategic commands ([Nintendo, Thracia 776](https://www.nintendo.com/jp/titles/50010000041662.html)).
  This supports the existing plan's reuse of the carry substrate, but not its assumption that custody
  ends in recruitment.
- *Fates* instead makes capture feed a between-map prison/persuasion loop. The important comparison
  is not which version to copy, but that “defeat non-lethally,” “hold prisoner,” and “persuade into
  the army” are separate player decisions. The distinction is summarized by the series reference's
  [Capture](https://fireemblem.fandom.com/wiki/Capture) and
  [Prison](https://fireemblem.fandom.com/wiki/Prison) articles.
- *Three Houses* shows a different recruitment experience: visible out-of-battle requests evaluate
  character-specific stat/skill requirements, with relationship progress lowering the barrier
  ([official recruitment guide](https://www.fireemblemawakening.com/three-houses/assets/media/Recruitment_Guide.pdf)).
  Recruitment therefore needs a trigger-agnostic requirement/action contract, as the existing plan
  proposes, rather than being synonymous with Talk.
- Support conversations are not just ordinary map Talk entries: their availability, chronology,
  archive/replay behavior, and relationship rewards differ. They can still share the same runner and
  presenter interfaces.

### Low-code author perspective

- FEBuilder's category-specific forms make common work discoverable: Turn, Talk, Map Object, and
  Always conditions each expose relevant fields, then point to an event and completion flag. Its
  weakness is the underlying ROM vocabulary and flag management; the visual layer reduces but does
  not remove state-coupling errors.
- Event Assembler offers full control through macros and event code. Its standard library includes
  character-event and allegiance-change helpers, demonstrating a productive compiled-command seam,
  but also the learning and maintenance burden of a large low-level opcode vocabulary
  ([EA standard library](https://github.com/StanHash/EAStandardLibrary/blob/master/EAstdlib.event)).
- SRPG Studio exposes Talk events and unit-affiliation commands directly. Its map tooling allows a
  player character to be placed as an enemy for recruitment, while affiliation changes preserve the
  identity ([SRPG Studio mapping reference](https://srpg-studio.fandom.com/wiki/Mapping)). A later
  release explicitly distinguished an enemy changed to player affiliation as a **guest** unit,
  evidence that control and durable roster membership need separate concepts
  ([SRPG Studio 1.302 notes](https://steamdb.info/patchnotes/15804916/)).
- RPG Maker MZ's ordered event-command list is approachable and expressive: Show Text, Show Choices,
  switches, variables, conditional branches, labels, jumps, common events, party changes, and plugin
  commands share one list ([official command reference](https://rpgmakerofficial.com/product/MZ_help-en/01_10.html)).
  Its event pages make triggers and conditions visible, and selected events can be tested directly
  ([official map-event reference](https://rpgmakerofficial.com/product/MZ_help-en/01_09_03.html)).
  The tradeoff is that free composition can duplicate logic and hide state in numbered switches.
- The best fit for Prometheus is therefore a hybrid: focused templates/forms for common Talk,
  support, recruit, and capture flows, all compiling to one validated, diffable data model.

### Full game-development perspective

- Yarn Spinner separates scripts, a runner, variable storage, localized line providers, presenters,
  and registered command handlers ([runner architecture](https://docs.yarnspinner.dev/components/dialogue-runner)).
  Its author language provides nodes, lines, options, jumps, variables, flow control, commands, and
  functions ([scripting fundamentals](https://yarnspinner.dev/docs/yarn/02-fundamentals/)). This is
  strong evidence for separating narrative traversal from presentation and game commands.
- Yarn also recommends a single source of truth rather than mirroring variables between narrative
  and game code, and its documented resume support is node-based rather than arbitrary-line-based
  ([Yarn FAQ](https://yarnspinner.dev/docs/faq/)). Prometheus needs stronger stable entry IDs if it
  keeps the existing between-line suspend requirement.
- Dialogic demonstrates the accessibility of a block-based Godot timeline editor with variables and
  built-in events ([Dialogic documentation](https://docs.dialogic.pro/)). It is a useful UX
  reference, not necessarily a dependency: Prometheus has campaign-pack loading, deterministic save,
  open registries, and tactical state constraints that a general VN plugin does not own.
- Godot custom Resources provide typed properties, Inspector editing, recursive serialization, and
  version-control-friendly `.tres`, and can later receive a custom `EditorPlugin`
  ([Godot Resource documentation](https://docs.godotengine.org/en/3.3/getting_started/step_by_step/resources.html)).
  Campaign packs already use canonical JSON, however, so the runtime format and the editor's internal
  model do not have to be identical as long as compilation is deterministic and lossless.

## Comparison with existing Prometheus plans and implementation

| Concern | Existing decision or implementation | Research pressure | Provisional disposition |
|---|---|---|---|
| Dialogue presentation | `[DLG-1]`: one scene-plus-log overlay | Supports, map barks, and story scenes want different layouts, but Yarn separates runner and presenters | Keep one runner; use profile-selected presenters/layouts rather than one compulsory visual composition |
| Dialogue data | `[DLG-2]`: flat addressable `line/choice/command/label` list | RPG Maker and Event Assembler validate ordered command lists; Yarn validates readable nodes and jumps | Keep compiled addressable entries; decide whether authors write node/script form or raw entries |
| Commands | `[DLG-2]`: scene ops and MET actions both called commands | External tools benefit from one list, but game effects must be validated and transactional | Split presentation commands from registered game actions in schema/permissions even if one runner dispatches both |
| State | `[DLG-5]`: choices set F6 flags or jump | Yarn warns against mirrored state; RPG Maker's arbitrary numbered variables become hard to audit | Shared campaign/map facts are authoritative; dialogue-local variables are ephemeral unless explicitly exported |
| Authoring | `[DLG-8]`: plain data now, dedicated editor later | FEBuilder/RPG Maker show immediate value from templates, field pickers, validation, and event tests | Define compiler/schema/validator first; ship a focused form/list editor before a full node graph |
| Talk | `[RCV-2]`: unit-targeted interactive trigger, directed or symmetric | Matches FEBuilder/SRPG Studio and classic FE | Keep; add discoverability, range, enemy initiation, and failure-policy decisions |
| Recruitment | `[RCR-1]`: faction flip plus permanent roster member | SRPG Studio guests and the requested temporary-control definition invalidate the coupling | Replace with an explicit transition spec over affiliation, controller, duration, and roster policy |
| Capture | `[RCR-5]`: non-lethal sleep then carry; captured unit becomes recruitable | Thracia supports carry/equipment interaction; Fates supports custody/persuasion separation | Keep optional carry path; make custody a first-class outcome independent of recruitability |
| Runtime implementation | No dialogue, recruit, Talk, custody, prison, or relationship runtime found on this branch; `Unit.team`/`FactionData` are the existing allegiance substrate | Clean slate permits separating concepts before save compatibility hardens | Resolve DRC questions before implementation; do not add one-off booleans or dialogue-only state transitions |

## Owner questions

Each question is implementation-plan blocking unless marked “later-tooling.” Recommendations are
provisional and may change when answers interact.

### A. Shared architecture and vocabulary

#### [DRC-1] Is dialogue one system or several?

- **A — One runner and one fixed full-screen presentation.** Pro: smallest number of code paths;
  every scene supports the same effects. Con: battle barks, supports, and long cutscenes inherit UI
  and authoring complexity they may not need.
- **B — Separate systems per use case.** Pro: each surface stays simple. Con: branching, localization,
  save/resume, logs, and commands are duplicated and drift.
- **C — One runner/data contract, multiple presentation and authoring profiles.** Pro: shared logic
  with purpose-fit UX; matches Yarn's runner/presenter split. Con: requires a clear profile contract
  and compatibility tests.

**Recommendation:** C. Treat “map talk,” “support,” “story,” “base,” and “bark” as profiles/templates,
not separate interpreters.

#### [DRC-2] What is a conversation's author-facing structure?

- **A — One flat entry list.** Pro: matches the current plan, runtime cursor, RPG Maker, and simple
  diffs. Con: long branches become difficult to navigate.
- **B — Named nodes containing ordered entries and explicit jumps.** Pro: readable chunks, reuse,
  graph visualization, and manageable branching. Con: adds node identity and call-stack semantics.
- **C — Arbitrary graph.** Pro: strongest visualization. Con: poor text diffs, complicated cycles,
  resume, localization, and validation.

**Recommendation:** B, compiled to stable flat instructions if the runtime benefits. Nodes should be
organization/resume boundaries, not scene-owned mutable objects.

#### [DRC-3] What is the source format shipped by campaign packs?

- **A — Typed Godot `.tres` Resources.** Pro: built-in Inspector and typed references. Con: awkward
  bulk writing, external tooling, pack conversion, and merge review.
- **B — Canonical JSON.** Pro: matches Tier-2 campaign packs, portable, easy to validate and diff.
  Con: verbose for prose and weak without an editor/schema.
- **C — A readable dialogue DSL compiled to canonical JSON.** Pro: best writer experience plus safe
  runtime data. Con: compiler, source maps, and two artifact forms must be maintained.

**Recommendation:** B for the first slice, with a lossless editor and an optional C front end later.
Do not require authors to edit `.tres` arrays for large conversations.

#### [DRC-4] How are entries and nodes identified?

- **A — Array indexes.** Pro: minimal data. Con: inserting a line invalidates saves, references, VO,
  localization, and test snapshots.
- **B — Author-written stable IDs.** Pro: durable references and readable diagnostics. Con: naming
  burden and collision risk.
- **C — Tool-generated stable IDs plus optional human aliases.** Pro: durable and low effort. Con:
  hand authors need a supported generation/check workflow.

**Recommendation:** C. IDs must be unique within a pack-qualified conversation namespace and never
derived from text or current position.

#### [DRC-5] Where may dialogue state live?

- **A — Only shared requirement facts/flags/variables.** Pro: one source of truth and easy saves.
  Con: temporary counters and local branch state pollute global namespaces.
- **B — Dialogue owns all narrative variables.** Pro: self-contained writing. Con: gameplay and
  dialogue state diverge and cross-system conditions become opaque.
- **C — Ephemeral conversation locals plus explicit reads/writes through registered shared-fact
  actions.** Pro: clear ownership and composability. Con: authors must distinguish local from durable.

**Recommendation:** C. A local is discarded at completion unless an explicit action commits a shared
fact.

#### [DRC-6] How are presentation commands separated from gameplay effects?

- **A — One unrestricted command registry.** Pro: simple and extensible. Con: skip, preview, resume,
  and validation cannot safely distinguish cosmetic from stateful commands.
- **B — Closed hardcoded command enum.** Pro: easy audit. Con: violates the project's open-registry
  rule and forces engine edits for content growth.
- **C — Two open registries with declared metadata:** presentation cue versus game action, including
  parameter schema, skip behavior, replay behavior, authority, and reversibility. Pro: extensible and
  auditable. Con: more registry contract work.

**Recommendation:** C.

#### [DRC-7] When do stateful dialogue actions commit?

- **A — Immediately as encountered.** Pro: intuitive scripting. Con: cancel, skip, crash, suspend,
  and rewind can duplicate partial consequences.
- **B — Buffer every effect until conversation end.** Pro: atomic. Con: later lines cannot naturally
  observe earlier effects and long scenes hide reward timing.
- **C — Explicit transaction boundaries: atomic conversation by default, with author-declared commit
  points for long/interactive scenes.** Pro: deterministic and flexible. Con: more author concepts.

**Recommendation:** A narrow v1 should use B; reserve C in the schema and runner after its rewind and
save semantics are specified.

#### [DRC-8] What may skip/fast-forward do?

- **A — Skip presentation only; execute every game action in order.** Pro: state is invariant. Con:
  costly effects or choice-dependent waits require metadata.
- **B — Jump to the end state.** Pro: fastest. Con: requires a trustworthy projection of arbitrary
  commands and can miss intermediate conditions.
- **C — Authors mark commands skippable.** Pro: flexible. Con: easy to author a state-divergent skip.

**Recommendation:** A. Skip must stop at unresolved choices and must not alter outcomes.

#### [DRC-9] What is the save/resume boundary?

- **A — Conversations are atomic and cannot be saved mid-run.** Pro: smallest first build. Con: poor
  experience for long story scenes.
- **B — Save after any stable entry using conversation/node/entry IDs plus traversed choices.** Pro:
  fulfills `[DLG-11]`. Con: scene reconstruction and version migration are substantial.
- **C — Save only at explicit checkpoints/nodes.** Pro: authors control safe reconstruction; less
  state. Con: save availability may be uneven.

**Recommendation:** A for v1, C as the long-term contract. Explicit checkpoints can usually be every
completed line while allowing authors/tools to exclude unsafe spans.

#### [DRC-10] How is text localized and connected to voice/portraits?

- **A — Inline source text.** Pro: excellent writing flow. Con: unstable localization identity and
  difficult VO tracking.
- **B — External text keys only, as currently planned.** Pro: stable localization. Con: low-code
  authors cannot read the conversation without resolving another file.
- **C — Stable line ID plus source-language text in the authoring view; export localized tables and
  optional VO/cue references keyed by line ID.** Pro: readable and durable. Con: compiler/editor work.

**Recommendation:** C; canonical pack JSON may store either source text or a table reference, but the
validator must produce a single stable line catalogue.

### B. Player and low-code-author experience

#### [DRC-11] How visible is Talk/recruit/capture eligibility to players?

- **A — Hidden unless currently actionable.** Pro: classic discovery and secrets. Con: guide
  dependence and accidental kills.
- **B — Always expose candidates, valid actors, and unmet requirements.** Pro: informed strategy.
  Con: spoilers and reduced discovery.
- **C — Authored disclosure policy (`secret`, `hinted`, `explicit`) using the existing hidden versus
  shown-disabled requirement vocabulary.** Pro: campaign-specific tone. Con: authors must write hints.

**Recommendation:** C, with `explicit` as the accessibility-friendly default and map/intel UI able to
show known Talk pairs.

#### [DRC-12] From what range and direction can Talk occur?

- **A — Adjacent and directed actor-to-target.** Pro: classic spatial puzzle. Con: repetitive and can
  force fragile positioning.
- **B — Symmetric adjacency.** Pro: fewer soft failures. Con: target-turn initiation needs rules.
- **C — Authored interaction descriptor: directed/symmetric, range predicate, allowed phases, and
  whether either side may initiate.** Pro: supports classic, radio, base, and enemy-initiated talks.
  Con: more validation.

**Recommendation:** C with a directed-adjacent template.

#### [DRC-13] What happens to the acting unit after a successful Talk/recruit/capture interaction?

- **A — Action ends.** Pro: predictable FE convention. Con: harsh for informational Talk.
- **B — Action remains available.** Pro: friendly. Con: movement/attack exploits after side changes.
- **C — Authored action-cost policy selected from validated templates (`end_activation`,
  `consume_minor_action`, `free_once`).** Pro: flexible and explicit. Con: depends on the future
  action-economy seam.

**Recommendation:** A for v1; reserve C rather than a boolean.

#### [DRC-14] How should choices communicate mechanical consequences?

- **A — Narrative labels only.** Pro: immersion. Con: irreversible recruitment/custody outcomes may
  surprise players.
- **B — Always show exact effects.** Pro: informed consent. Con: spoilers and UI noise.
- **C — Author supplies optional consequence preview and confirmation severity; accessibility can
  force previews for irreversible outcomes.** Pro: adaptable. Con: extra authoring fields.

**Recommendation:** C. Release, execute, dismiss, or permanently recruit should default to confirm.

#### [DRC-15] What dialogue history and replay surfaces exist?

- **A — Current-scene backlog only.** Pro: matches `[DLG-1]`, small scope. Con: supports/story cannot
  be revisited later.
- **B — Global archive of every conversation.** Pro: player-friendly. Con: spoilers, branch variants,
  dynamic names, and state-dependent lines complicate replay.
- **C — Current backlog for all; author-tagged archive entries for supports/story, storing viewed
  route/variant metadata.** Pro: purpose-fit. Con: needs archive policy and replay-safe commands.

**Recommendation:** C; archive replay must suppress gameplay actions.

#### [DRC-16] What is the minimum authoring tool?

- **A — Hand-authored JSON plus schema errors.** Pro: cheapest foundation. Con: inaccessible to many
  campaign authors and poor for asset/ID discovery.
- **B — Godot list/form editor with typed entry insertion, pickers, validation, preview, duplicate,
  and templates.** Pro: captures most RPG Maker/FEBuilder value without graph complexity. Con: editor
  plugin maintenance.
- **C — Full node graph/timeline first.** Pro: rich scene visualization. Con: delays runtime and can
  obscure diffs.

**Recommendation:** B. “Map recruit talk,” “support rank scene,” and “capture outcome” wizards should
emit ordinary validated data, never special runtime objects.

#### [DRC-17] What validation must block pack activation/export?

- **A — Syntax and referenced-file existence only.** Pro: easy. Con: broken jumps, impossible choices,
  duplicate consequences, and invalid unit transitions ship.
- **B — Full static validation:** IDs, graph reachability, missing/empty option sets, requirement and
  action schemas, asset/text references, transaction/skip metadata, unsafe cycles, resume points, and
  recruit/capture target compatibility. Pro: safe low-code authoring. Con: some dynamic conditions
  remain unknowable.
- **C — B plus bounded simulation/test cases authored as fixtures.** Pro: catches state-dependent
  failures. Con: higher tool cost.

**Recommendation:** B is mandatory; C should be supported for campaign test suites and editor preview.

#### [DRC-18] How are reusable fragments handled?

- **A — Copy/paste entries.** Pro: simple. Con: dialogue and consequences drift.
- **B — Callable conversation nodes/fragments with parameters and an explicit return.** Pro: reusable
  greetings, tutorials, custody menus. Con: call stack/resume and localization context grow complex.
- **C — Only reusable event actions/templates, not prose fragments.** Pro: simpler narrative flow.
  Con: authors still duplicate common prose.

**Recommendation:** C for v1; add B only with typed parameters and recursion rejection.

### C. Recruitment state and transitions

#### [DRC-19] What concepts replace the overloaded `Unit.team` assumption?

- **A — Keep one faction/team field.** Pro: minimal code change. Con: temporary control, guests,
  charm, prisoners, roster membership, and diplomacy become boolean exceptions.
- **B — Separate `affiliation_id`, `controller_id`, `roster_status`, and `custody_status`; derive
  hostility and turn participation through registries.** Pro: accurately models the requested scope.
  Con: migration touches AI, objectives, turn order, UI, save, and targeting.
- **C — Keep affiliation, add a generic stack of unit-state overrides.** Pro: flexible effects. Con:
  opaque precedence and difficult save/debug behavior.

**Recommendation:** B. Temporary magical control may be an override/effect, but its resolved
controller must still be queryable through one authoritative service.

#### [DRC-20] What does a recruitment transition specify?

- **A — Target faction only.** Pro: concise. Con: silently implies permanence and roster policy.
- **B — A typed transition `{target_affiliation, target_controller, roster_policy, duration,
  expiration_outcome, activation_policy}`.** Pro: explicit and validates temporary recruitment.
  Con: more author fields.
- **C — Arbitrary action list.** Pro: maximum flexibility. Con: authors can create internally
  inconsistent combinations.

**Recommendation:** B, exposed through templates such as `permanent_join`, `map_guest`,
`turn_control`, and `defect_to_third_faction`.

#### [DRC-21] Which recruitment durations are required for v1?

- **A — Permanent player roster only.** Pro: smallest compatible slice. Con: does not fulfill the
  agreed recruitment definition.
- **B — Permanent plus until-map-end guest.** Pro: covers the most useful temporary case. Con: not
  turn-limited charm or scripted return.
- **C — Registry/predicate expiration supporting permanent, map end, N activations/rounds, fact
  change, conversation outcome, or explicit release.** Pro: complete. Con: complex lifecycle hooks.

**Recommendation:** B in the first implementation, with C-shaped serialized data and explicit
unsupported duration rejection.

#### [DRC-22] When does a newly controlled on-map unit become actionable?

- **A — Immediately, regardless of prior activation.** Pro: satisfying. Con: double turns.
- **B — Preserve activation state; if already acted, remain done.** Pro: deterministic and hard to
  exploit. Con: a recruited enemy may do nothing until next round.
- **C — Transition authors select refresh/preserve/end, with UI preview.** Pro: flexible. Con:
  balance exploits and added author burden.

**Recommendation:** B by default; allow C only as an explicit registered action with warning-level
validation.

#### [DRC-23] What unit data survives control/faction changes?

- **A — Preserve the same runtime unit object, HP/status/inventory/growth/history/AI profile.** Pro:
  stable identity and intuitive continuity. Con: hostile-only AI/orders and inventory ownership need
  reconciliation.
- **B — Despawn and instantiate a roster template.** Pro: clean player-ready data. Con: loses battle
  state and risks duplication; SRPG tools historically require awkward copying when identity cannot
  cross affiliation.
- **C — Preserve identity/state, then apply an authored transition patch with validated allowed
  fields.** Pro: continuity plus controlled changes. Con: patch schema.

**Recommendation:** C; default patch is empty except controller/affiliation/roster fields.

#### [DRC-24] When and how does permanent roster insertion occur?

- **A — Immediately on the map.** Pro: save/state is straightforward and unit details work at once.
  Con: roster capacity, convoy, duplicate identity, and later betrayal need answers.
- **B — Mark pending and commit at map results.** Pro: transactional campaign state. Con: permadeath,
  retreat, suspend, and mid-map deployment consumers see an ambiguous guest.
- **C — Immediate membership in a typed `pending_member` status; results finalize or disposition
  rules resolve it.** Pro: explicit and reversible. Con: adds a roster state.

**Recommendation:** C if roster limits or map-failure rollback exist; otherwise A with ledger-backed
rollback. Decide alongside save/rewind semantics.

#### [DRC-25] How are recruitment requirements authored?

- **A — Fields on the recruitable unit.** Pro: easy discovery. Con: cannot express map/route/pair-
  specific circumstances without bloating unit data.
- **B — Only on triggers/events, as `[RCR-4]` proposes.** Pro: composable shared predicates. Con:
  author tools may not show all ways a unit can join.
- **C — Unit supplies identity/default hints; transition opportunities own authoritative predicates,
  outcome, disclosure, and eligible actor/target selectors.** Pro: clean split and strong author UX.
  Con: cross-reference validation needed.

**Recommendation:** C, retaining the intent of `[RCR-4]` while removing a potentially misleading
`recruitable` truth flag.

#### [DRC-26] Which sources may recruit?

- **A — Talk only.** Pro: focused. Con: excludes automatic joins, villages, choices, support/stat
  checks, purchases, charm, and scripted defections.
- **B — Any registered event action can invoke the same transition.** Pro: matches `[RCV-4]` and
  Three Houses-like recruitment. Con: requires context validation.
- **C — Each source gets a bespoke recruit path.** Pro: tailored UI. Con: duplicated state logic.

**Recommendation:** B. Source-specific templates should compile to the same transition action.

### D. Capture and prisoner lifecycle

#### [DRC-27] Which capture-entry mechanics are in scope?

- **A — Existing planned path only: non-lethal would-be kill applies sleep, then carry off-map.** Pro:
  reuses Source/Style and carry. Con: two-step, may make capture eligibility unclear, and conflates
  incapacitation with custody.
- **B — Thracia-like Capture combat command that resolves directly into carried custody with combat
  penalties.** Pro: clear tactical choice and risk. Con: new combat forecast/action behavior.
- **C — Registered capture methods: non-lethal/carry, direct capture attack, surrender, dialogue,
  objective/script.** Pro: author flexibility and clean outcome. Con: broader initial build.

**Recommendation:** C-shaped data, with A as the first method and a first-class `take_custody` action
so dialogue/surrender do not fake sleep.

#### [DRC-28] What determines physical capture eligibility?

- **A — Fixed size/build comparison.** Pro: legible Thracia-style rule. Con: excludes magic,
  restraints, surrender, and story capture.
- **B — Status only (incapacitated/surrendered).** Pro: simple. Con: any unit can carry any target.
- **C — Registered requirement predicate per capture method, with shared selectors for status,
  relation, size/carry capacity, immunity/tags, equipment, HP, and actor traits.** Pro: open and
  authorable. Con: UI must explain failures.

**Recommendation:** C with a standard `incapacitated_and_carryable` profile.

#### [DRC-29] What is the on-map custody representation?

- **A — Captive becomes cargo on a carrier; one identity remains in map state.** Pro: tactical rescue,
  escape, and carrier penalties; aligns with carry. Con: requires carried-unit targeting and save.
- **B — Captive is removed immediately into a map prisoner list.** Pro: simpler board state. Con:
  loses escort risk and recovery play.
- **C — Capture method selects `carried`, `restrained_on_tile`, or `removed_to_custody`, each backed
  by one custody record.** Pro: broad scenarios. Con: more states and objective hooks.

**Recommendation:** A for combat capture; allow B for scripted surrender. Reserve C's shared custody
record so the two paths converge.

#### [DRC-30] What happens to a captive's inventory?

- **A — Immediate automatic transfer to captor/convoy.** Pro: clear reward. Con: capacity, ownership,
  escape, release, and ethics become awkward.
- **B — Inventory remains with captive until an explicit search/confiscate action.** Pro: meaningful
  custody choice and reversible release. Con: more UI/actions.
- **C — Authored custody policy (`retain`, `trade_while_carried`, `confiscate_to`, `drop`) with
  capacity/overflow handling.** Pro: supports Thracia and story prisoners. Con: complexity.

**Recommendation:** B as default, C as the contract. Confiscation must be ledgered and release must
not silently duplicate or delete items.

#### [DRC-31] What can happen to a captive during and after a map?

- **A — Hold until map end, then automatically become recruitable.** Pro: matches the old plan.
  Con: violates custody/recruit separation and erases player agency.
- **B — Campaign-authored automatic disposition at map end: release, transfer, escape, remain held,
  or scripted outcome.** Pro: story control. Con: limited player agency.
- **C — A custody roster with authored available actions and requirements: hold, move, release,
  exchange, ransom, interrogate, persuade/recruit, trial, or other registered outcomes.** Pro: full
  player/author expressiveness. Con: substantial prep/base UI and sensitive-content policy.

**Recommendation:** B for the first slice, with a minimal custody record; C is the expansion target.
Recruitment is one possible registered outcome, never the automatic definition of capture.

#### [DRC-32] Can prisoners escape or be rescued, and who controls them?

- **A — No agency while captive.** Pro: simple. Con: escort/custody lacks counterplay.
- **B — Deterministic authored events only.** Pro: story-friendly and testable. Con: not systemic.
- **C — Custody security and escape/rescue predicates drive events; a captive has no normal turn
  controller until released, but remains targetable by defined interactions.** Pro: systemic and
  data-driven. Con: AI/objective complexity.

**Recommendation:** B initially; design the custody record and signals so C does not require changing
identity or save format.

#### [DRC-33] How do objectives, AI, save/rewind, and versioning observe these transitions?

- **A — Each system listens for faction change/death/capture separately.** Pro: local changes. Con:
  missed cases and order-dependent bugs.
- **B — One authoritative unit-transition service emits a structured before/after record and applies
  it transactionally; objectives, turn order, AI, UI, roster, dialogue facts, ledger, and saves consume
  the same result.** Pro: deterministic, testable, and compatible with `[VIL-8]` hostile-presence
  objectives. Con: central service design work.
- **C — Recompute everything from the unit each frame.** Pro: fewer signals. Con: cannot explain cause,
  disposition, history, or rollback.

**Recommendation:** B. The record should include cause, actor, target, old/new affiliation,
controller, roster/custody/activation states, inventory transactions, duration/expiry, and emitted
facts. Pack schema versions must reject or migrate unsupported transition/action versions before
activation.

## Cross-question decisions required before an implementation plan

The answers should be resolved in this order because later choices depend on earlier ones:

1. `[DRC-19..21]` — unit state dimensions and recruitment transition contract.
2. `[DRC-27..33]` — custody record, entry methods, outcomes, and authoritative transition service.
3. `[DRC-1..10]` — dialogue runner, data, state, effects, transaction, and resume boundaries.
4. `[DRC-11..18]` — player disclosure and minimum authoring/validation tools.
5. `[DRC-22..26]` — activation, preservation, roster commit, requirements, and recruitment sources.

An implementation plan should not be written by merely accepting every recommendation. It should
record the owner's selected option for every `[DRC]` item, reconcile dependencies between selections,
then divide delivery into independently testable slices. At minimum, tests must cover stable identity,
temporary-control expiry, already-acted conversion, third-faction hostility, capture/release inventory
round trips, map-end custody, objective re-evaluation, suspend and Rewind, skip equivalence, dialogue
branch resume, invalid pack rejection, and replay with stateful commands suppressed.
