---
Role: dated
Type: design
Status: Active - research note
Last verified: 2026-06-28
---

# Minigame Activity Type Initial Specs

**Started:** 2026-06-28. Follow-up to
[`minigame_scripting_runtime_research_2026-06-28.md`](minigame_scripting_runtime_research_2026-06-28.md).

**Purpose.** Turn the first three recommended activity prototypes into
implementation-shaped spec sheets:

- PuzzleScript-style grid puzzles;
- QTE / timing challenges;
- blackjack / card-table activities.

These specs are **activity templates**, not full scripting languages. They are
designed to prove the shared activity seam before any public code/VM decision.

## Shared Activity Contract

All three activity types use the same host shape:

- **Registry:** an `ActivityRegistry` entry declares `activity_id`, template
  kind, config schema, context schema, result schema, reward bounds, allowed
  launch surfaces, and save policy.
- **Launch:** callers use one `launch_activity` primitive from prep menus,
  on-map activations, dialogue commands, and `[MET]` story/map-event actions.
- **Runner:** `ActivityRunner` captures input, presents the activity viewport,
  routes deterministic RNG, enforces budgets, and returns one typed result.
- **Result bridge:** activities never mutate campaign state directly. The host
  maps typed results to registered effects: gold/resources, EXP/bonus EXP,
  items, flags/typed vars, MET actions, objective state.
- **Save:** v1 activity templates are atomic. Finish, fail, or cancel, then
  return to the caller. No mid-activity save until a real activity proves it is
  needed.
- **Authoring:** configs are plain data with structured validation errors and
  editor-facing metadata. No public pack GDScript.

## Spec A — Grid Puzzle Activity

### Player Shape

A one-screen or multi-room tile puzzle launched from a story beat, map object,
prep panel, or dialogue command. Player moves an avatar/cursor on a bounded
grid and manipulates puzzle objects. Success returns a result such as opening a
gate, granting an item, setting a flag, changing an objective, or paying a
small reward.

Good first examples:
- push crates onto switches;
- slide blocks on ice;
- rotate mirrors to redirect beams;
- route power through logic gates;
- maze/key/door rooms;
- conveyor-belt or pressure-plate puzzles.

### Authoring Shape

The template is **PuzzleScript-inspired**, not full PuzzleScript.

```yaml
activity_id: gate_lock_01
kind: grid_puzzle
viewport: { cols: 12, rows: 8, tile_px: 24 }
tiles:
  floor: { layer: floor, sprite: lock_floor }
  wall: { layer: solid, sprite: lock_wall, blocks_move: true }
  player: { layer: actor, sprite: lock_cursor, controllable: true }
  crate: { layer: object, sprite: brass_block, pushable: true }
  switch: { layer: floor, sprite: switch_off }
legend:
  ".": [floor]
  "#": [wall]
  "P": [floor, player]
  "C": [floor, crate]
  "S": [floor, switch]
levels:
  - id: room_a
    rows:
      - "########"
      - "#P.C.S.#"
      - "#......#"
      - "########"
rules:
  - id: push_crate
    trigger: move_into
    actor: player
    target: crate
    effect: push_target
win:
  all:
    - every: crate
      on: switch
result_map:
  success:
    - action: set_var
      var: gate_open
      value: true
```

### Runtime Model

- Deterministic step loop: one input action advances one puzzle tick.
- Board state is a bounded tile stack per cell.
- Collision layers prevent impossible overlaps.
- Built-in primitive rules cover v1: move, push, pull, block, toggle, transform
  tile, emit beam, rotate object, open/close gate, check condition.
- Rule processing is deterministic: explicit rule priority, then stable id.
- Undo is activity-local and optional; it does not touch the tactical rewind
  system unless a later design chooses to connect them.

### Validation

Fail loud at load if:
- legend references unknown tiles;
- two tiles occupy the same exclusive collision layer illegally;
- rule ids/primitive handlers are unknown;
- rule parameters are wrong for the primitive;
- levels are non-rectangular unless explicitly allowed;
- win conditions reference unknown tiles/layers;
- result mappings exceed host-declared reward bounds.

### Build Slices

1. One-room Sokoban subset: tiles, layers, movement, push, simple win.
2. Doors/switches and multi-room level list.
3. Beam/mirror or logic-gate primitives.
4. Prose conversion guide from PuzzleScript concepts to this template.
5. Subset importer that emits this template and reports unsupported constructs.

### Full PuzzleScript Compatibility Path

Keep the native template as the runtime target. Compatibility grows by import
tier:

- **Tier 1:** objects, legend, collision layers, levels, simple win conditions.
- **Tier 2:** simple directional movement/push rules.
- **Tier 3:** common commands/messages/sounds where they map cleanly to host
  effects or presentation cues.
- **Tier 4:** broader rule-order and edge-case compatibility only if demand
  justifies it.

Do not call the feature "PuzzleScript support" until importer tiers are explicit
and tested. Call it "PuzzleScript-inspired grid puzzles" before then.

### Other Uses

Once proven, this template can power lockpicks, dungeon mechanisms, magical
circuits, training-room tactics puzzles, route-the-convoy puzzles, trap rooms,
and safe tutorial sandboxes.

## Spec B — QTE / Timing Challenge Activity

### Player Shape

A short timing game that asks the player to press, hold, release, mash, or
choose actions inside authored windows. It can represent lockpicking,
disarming a trap, interrupting a ritual, catching a fish, forging, dodging a
hazard in a cutscene, or a support/persuasion beat.

### Authoring Shape

```yaml
activity_id: lockpick_easy_01
kind: qte_sequence
viewport: { preset: compact_meter }
accessibility_profile: standard_qte
prompts:
  - id: pin_1
    type: timed_press
    action: ui_accept
    appear_at_ms: 400
    windows:
      perfect: { start_ms: 850, end_ms: 980, points: 100 }
      good: { start_ms: 760, end_ms: 1080, points: 50 }
    miss_penalty: 1
  - id: tension
    type: hold_release
    action: ui_accept
    hold_min_ms: 500
    release_window_ms: { start: 1200, end: 1500 }
  - id: finish
    type: mash_meter
    action: ui_accept
    duration_ms: 1800
    target_count: 8
result_thresholds:
  success: { min_score: 180, max_misses: 1 }
  perfect: { min_score: 250, max_misses: 0 }
result_map:
  success:
    - action: set_var
      var: lock_open
      value: true
```

### Runtime Model

- Activity-local state machine: intro -> prompt -> resolve -> next prompt ->
  result.
- Input uses project actions (`ui_accept`, directional actions, etc.), not raw
  keys or platform events.
- Timing uses activity time. No wall-clock reads.
- Result is score/rank/misses/streak plus optional per-prompt payload.
- RNG is usually unnecessary. If a sequence randomizes, use `RngService` and
  record the seed in the activity result if rewards depend on it.

### Prompt Types

First useful set:
- `timed_press`;
- `sequence_press`;
- `hold_release`;
- `mash_meter`;
- `direction_choice`;
- `rhythm_tap`.

Avoid custom per-QTE code. New prompt families are registry entries with their
own schemas.

### Accessibility

The template should expose author/player knobs:
- widen timing windows;
- reduce mash targets or convert mash to hold;
- slow prompt speed;
- provide non-timeout mode for critical story gates;
- forbid hard progression failure if the author marks the activity as required.

### Validation

Fail loud at load if:
- prompt action ids are not registered input actions;
- timing windows overlap incoherently;
- perfect/good/fail thresholds cannot be reached;
- required story activities can hard-fail without an alternate result path;
- result mappings exceed reward bounds.

### Build Slices

1. Timed press + score/rank result.
2. Hold/release + mash-meter prompt types.
3. Accessibility modifiers.
4. Dialogue/map-event launch examples.
5. Rhythm or sequence prompts if real content needs them.

### Other Uses

Once proven, QTEs can power lockpicks, fishing, forging quality, trap disarm,
ritual interruptions, chase/escape beats, training drills, and non-combat
support checks where the author wants a playable action instead of a pure
stat predicate.

## Spec C — Blackjack / Card-Table Activity

### Player Shape

A card-table activity launched from a casino prep panel, map tavern, dialogue
scene, story event, or PvP lobby. The first implementation targets blackjack
because it stresses stakes, deterministic shuffle, repeat rounds, result
mapping, and a richer UI than QTEs without needing arbitrary scripting.

### Authoring Shape

```yaml
activity_id: tavern_blackjack_01
kind: card_table
game: blackjack
stakes:
  resource: gold
  min_bet: 10
  max_bet: 100
  default_bet: 20
deck:
  decks: 1
  shuffle: per_session
rules:
  dealer_hits_soft_17: false
  blackjack_payout: "3:2"
  allow_double: true
  allow_split: false
  allow_surrender: false
rounds:
  mode: repeat_until_leave
  max_rounds: 10
result_map:
  session_win:
    - action: set_var
      var: tavern_won_blackjack
      value: true
```

### Runtime Model

- Card table owns local deck/shoe, hands, wager, round state, and settlement.
- Host resource ledger quotes and commits stakes. The activity should reserve
  or debit a bet through a host transaction, then settle through the result
  bridge.
- Deterministic shuffle uses `RngService` because rewards depend on card order.
- Basic flow: choose bet -> deal -> player action loop -> dealer loop -> settle
  -> repeat/leave.
- First actions: hit, stand, double, leave. Split/surrender can wait.

### Dialogue Relationship

Do **not** implement real blackjack inside the dialogue runner. Dialogue can
wrap the table:

1. conversation line / banter;
2. `command: launch_activity { activity_id: tavern_blackjack_01 }`;
3. result stored in a dialogue/MET context var;
4. result-aware dialogue branch.

Dialogue-only blackjack would require card/deck/score/payment commands that are
specific to one minigame. That would bloat DLG and duplicate ActivityRunner.

### Validation

Fail loud at load if:
- resource id is unknown or wrong scope;
- bet min/default/max are incoherent;
- payout ratio is malformed;
- rule combo is unsupported by the built-in blackjack handler;
- result mapping can pay outside declared bounds;
- repeat mode has no exit path.

### Build Slices

1. Single-hand blackjack: hit/stand, dealer rule, deterministic deck, no repeat.
2. Betting through the resource ledger and payout through result bridge.
3. Repeat rounds and leave/cash-out.
4. Double-down.
5. Optional split/surrender only if casino scope demands it.

### Other Uses

Once proven, the card-table template can support dice games, roulette/wheel
games, memory cards, tarot/event draws, tavern wagers, PvP lobby wagers, clue
draws, or "draw a fate card" story events that return rank/payload instead of
directly mutating state.

## Dialogue / Cutscene Tooling Assessment

### What Dialogue Already Provides

The dialogue design is more than text boxes. It defines:

- a stage region over map or special background;
- stage elements independent of speakers;
- explicit z-layers;
- character effects, portrait transforms, and scene-wide filters;
- line/choice/command/label entries;
- branch gating through `[REQ]`;
- mid-conversation suspend state at entry boundaries.

Those are useful presentation primitives, especially the stage element and
effect/layer model.

### What Activities Should Reuse

Reuse the **presentation vocabulary**, not the dialogue runner:

- stage elements, z-layers, and effects for activity intros/outros;
- special background / map-transparent background handling;
- raw-loaded portrait/background asset rules;
- result-aware dialogue branches before/after activities;
- dialogue commands as one launch surface for `launch_activity`.

For example:
- QTE can use DLG-style scene filters and stage elements for a lockpick or
  trap-disarm cut-in.
- Blackjack can use DLG-style portraits/stage elements for dealer reactions and
  table ambience.
- Grid puzzles can use DLG-style transitions, camera focus, and map/special-bg
  stage framing around the puzzle.

### What Should Stay Separate

Do not fold dialogue/cutscenes into ActivityRunner wholesale:

- Dialogue is a narrative runner with text history, choices, branch trail, and
  entry-boundary suspend.
- Activities are interactive local game loops with input capture, local state,
  timing/board/card state, deterministic RNG, reward bounds, and typed results.
- Forcing dialogue into activities would make conversations pay the complexity
  cost of game loops.
- Forcing activities into dialogue would make DLG grow one-off card, puzzle, and
  timing commands.

### Shared Substrate Recommendation

Extract a reusable **StagePresentation** layer when building DLG:

- stage elements;
- layer ordering;
- background source;
- visual effect cues;
- text ids for labels/tooltips when needed;
- animation speed/playback metadata.

DLG consumes StagePresentation plus chat-log/choice semantics. ActivityRunner
may optionally consume StagePresentation for non-interactive presentation around
an activity. The two runners stay separate, and both remain open-registry
consumers.

### Authoring Tool Implication

The eventual dialogue timeline/editor can help author **presentation beats** for
activities, but it should not become the activity logic editor. Activity logic
needs template-specific forms:

- grid puzzle board/rule editor;
- QTE timeline/window editor;
- card-table rule/stakes editor.

They can share preview infrastructure and validation reports through the
Designer Authoring Contract.

## Shared Test Obligations

When these templates are implemented, add tests for:

- `ActivityRegistry` rejects unknown kinds and bad schemas;
- each launch surface can call `launch_activity` with correct context;
- activities return typed results without direct campaign mutation;
- reward bounds reject oversized payouts;
- deterministic RNG gives reproducible blackjack shuffles;
- QTE timing windows resolve at boundaries;
- grid puzzle rule ordering is stable;
- dialogue command launch resumes dialogue with the activity result.

## Cross-References

- Minigame runtime research:
  [`minigame_scripting_runtime_research_2026-06-28.md`](minigame_scripting_runtime_research_2026-06-28.md).
- `[SAC]` scene-backed activities / `ActivityRunner` seam:
  [`../registers/shop_activate_configs_open_questions_2026-06-27.md`](../registers/shop_activate_configs_open_questions_2026-06-27.md).
- `[DLG]` dialogue/cutscene stage and command model:
  [`../registers/dialogue_conversation_system_open_questions_2026-06-25.md`](../registers/dialogue_conversation_system_open_questions_2026-06-25.md).
- Registry and authoring contracts:
  [`registry_manifest_contract_2026-06-28.md`](registry_manifest_contract_2026-06-28.md),
  [`designer_authoring_contract_2026-06-28.md`](designer_authoring_contract_2026-06-28.md).
