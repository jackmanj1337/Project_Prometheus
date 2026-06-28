---
Type: design
Status: Active - research note
Last verified: 2026-06-28
---

# Minigame Scripting Runtime Research

**Started:** 2026-06-28. Research follow-up to scope-map #23 and the `[SAC]`
scene-backed activity / mini-game module seam.

**Purpose.** Decide what a small sandboxed author-facing activity runtime would
need before it is worth building, and keep the near-term architecture from
blocking future minigames.

## Prior Decisions Reviewed

- `[PHB]` chose **opt-in prep panels** on progression nodes: flat panel list,
  cosmetic theme/location label, node-scoped availability, free navigation, and
  immediate transaction commit.
- `[BEA]` chose **Arena as a PHB panel** that reuses sandboxed real combat,
  authored opponents, existing EXP/wexp/gold paths, and an atomic return to prep.
- `[SAC]` chose a unified **`map_objects` / `activate`** model and the **PHB
  dual-surface contract**: the same panel can be launched by a prep button or an
  on-map object, with per-instance variation.
- `[SAC]` also parked arbitrary minigames as **scene-backed activities**:
  launch a scene with context, receive a typed result, map that result to
  existing engine effects, and register activities through an open registry.
- `[EXT]` chose **data composition over author-authored engine logic** for core
  vocabularies. That decision still governs tactical-engine state mutation:
  minigame scripts may own local activity behavior, but engine changes must pass
  through registered result/effect primitives.

## Launch Surfaces

Activities must be launchable from every authored content surface that can host
a player-facing beat:

- prep menu / hub panel (`[PHB]`);
- on-map `activate` / panel-trigger (`[SAC]` + `[VIL-2]`);
- dialogue `command` (`[DLG]`), not just the shop-specific command;
- map/story event action (`[MET]`), including objective, flag, and chapter beats.

The shared primitive should be `launch_activity`, not a new branch per caller.
Each caller supplies a context dictionary with the relevant subjects:
`unit`/`shopper`, map object, dialogue speaker/participants, event payload,
stakes, parameters, and permitted result mappings.

## Existing Systems To Learn From

- **MiniScript.** A small language intended to be embedded in host games/apps;
  the host adds environment-specific intrinsic functions. Useful model if the
  project later wants a readable imperative script with a deliberately tiny host
  API. See the [MiniScript home page](https://miniscript.org/), the
  [MiniScript manual](https://miniscript.org/files/MiniScript-Manual.pdf), and
  the [Unity integration guide](https://miniscript.org/files/MiniScript-Integration-Guide.pdf).
- **Wren.** A small embeddable VM where the host explicitly binds foreign
  methods/classes. Good API-boundary inspiration: scripts see only what the host
  binds. See Wren's [embedding docs](https://wren.io/embedding/) and
  [foreign method binding](https://wren.io/embedding/calling-c-from-wren.html).
- **PICO-8 / TIC-80.** Fantasy consoles show the value of a fixed canvas,
  constrained APIs, callbacks, input helpers, sprite/map helpers, and hard
  budgets. They make small games possible because the box is narrow. See the
  [PICO-8 manual](https://www.lexaloffle.com/dl/docs/pico-8_manual.html) and
  [TIC-80 learn/API pages](https://tic80.com/learn).
- **PuzzleScript.** Strong model for grid/tile puzzles: objects, collision
  layers, declarative rewrite rules, win conditions, and levels. It suggests a
  narrower declarative activity type may cover many puzzle minigames more safely
  than a general scripting language. See the [PuzzleScript rules docs](https://www.puzzlescript.net/Documentation/rules.html).
- **Bitsy.** Shows how a very small world/dialog system can still support
  branching interactions and stateful author beats. Useful for dialogue-driven
  microgames. See [Bitsy dialog docs](https://make.bitsy.org/docs/tools/dialog/).
- **ink.** Good inspiration for narrative flow, choices, variables, diverts, and
  host integration points. Useful when a minigame is mostly choice/logic rather
  than real-time play. See [Writing with ink](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md).
- **Godot `Expression`.** Not a sandbox boundary for untrusted activity logic:
  expressions can call methods on a passed base instance. It can be useful for
  trusted editor conveniences, but not for public minigame code. See Godot's
  [Expression class docs](https://docs.godotengine.org/en/stable/classes/class_expression.html).

## Utility Floor

A scripting/activity runtime is only worth building if authors can make several
simple game shapes without engine edits:

- timing/QTE: hit a button in a window, mash, rhythm taps, hold/release;
- memory/matching: cards, symbol repeat, Simon-style sequences;
- casino: blackjack-like card draws, roulette/wheel, dice, simple betting;
- grid puzzle: sliding blocks, sokoban-like rules, maze navigation, logic gates;
- arcade-lite: dodging, collect-the-things, simple shooter, flappy-style motion;
- dialogue microgame: riddle, persuasion, clue selection, lockpick choice tree.

That floor implies these runtime capabilities:

- fixed-size activity viewport/canvas, with scale-to-fit inside the host UI;
- deterministic frame/update loop or turn-step loop;
- input API over project actions, not raw platform events;
- local variables, arrays/maps, simple functions, and bounded loops;
- sprite/tile/text drawing, basic sound cue playback, and optional animations;
- collision helpers for rectangles/circles/tilemaps;
- timers using activity time, not wall-clock;
- RNG routed through `RngService` when the result affects rewards/state;
- author-provided assets limited to the content-pack asset policy;
- result emission: `success/fail/cancel`, score, rank, payload;
- host-side result mapping to existing effects only: gold/resources, items,
  EXP/bonus EXP, flags/typed vars, MET actions, objective updates;
- atomic save policy at first: finish/cancel activity, then return. No
  mid-minigame save until a concrete activity proves it needs one.

## Runtime Shape

Recommended architecture:

1. **ActivityRegistry.** Built-in panels and future minigames register
   `activity_id -> launcher`, context schema, config schema, result schema,
   reward bounds, save policy, and allowed launch surfaces.
2. **ActivityRunner.** A single host screen/node that pushes an activity,
   captures input, provides the viewport, enforces time/instruction budgets, and
   returns a typed result.
3. **Result bridge.** The host maps results to existing `[MET]` / action-effect
   primitives. Activity code never directly mutates party gold, inventory,
   objectives, map objects, or TCV vars.
4. **Scene-backed first-party path.** For early built-in activities, a trusted
   Godot scene implements the activity behind the same ActivityRegistry contract.
5. **Sandboxed-script path, later.** If public authors need code, scripts run in
   a deliberately small VM/interpreter with no access to Godot nodes, OS,
   filesystem, network, threads, reflection, or arbitrary singletons.

## Sandbox API Shape

Expose capability objects, not the Godot engine:

- `game`: dimensions, delta/tick, pause/cancel request, end result;
- `input`: `pressed(action)`, `just_pressed(action)`, directional vector;
- `draw`: clear, sprite, tile, rect, text, line, particles from approved ids;
- `audio`: play approved cue id, stop cue;
- `rng`: deterministic integer/range/shuffle helper;
- `assets`: resolve only activity-declared asset ids;
- `state`: local activity state only;
- `host`: read-only context values and `finish(result)`.

Do not expose `Node`, `Object`, `ResourceLoader`, `FileAccess`, `OS`, arbitrary
autoloads, or direct setters for campaign/map state.

## Other Project Uses

The same ActivityRegistry / ActivityRunner can support more than side-content:

- dialogue challenges: persuasion, riddles, evidence selection, support checks;
- map object puzzles: locks, levers, magic circuits, timed switches;
- training drills: paid stat/source/style training as a playable exercise;
- forging/repair minigames with bounded quality tiers;
- fishing/garden/camp activities that feed resources, supports, or morale;
- tutorial sandboxes that teach a mechanic without entering a real map;
- story set pieces such as hacking a gate, decoding a relic, or escaping a trap;
- PvP lobby/buy-phase side contests if the author wants optional wagers.

## Recommendation

Do **not** build a general sandboxed language for v1. Build the cheap seam now:
`ActivityRegistry`, `launch_activity`, `ActivityRunner`, context/result schemas,
and the result bridge. Keep built-in activities as trusted scenes at first.

For post-v1 public authoring, prototype two narrower tiers before choosing a
general language:

1. **Declarative activity templates** for QTE, card/dice, match/memory, and
   grid-rule puzzles. This likely covers many author needs with better
   validation and editor support.
2. **Small imperative VM** only if template demand proves insufficient. MiniScript
   and Wren are the strongest comparators because both are designed for host
   embedding. The host API should remain fantasy-console-like: fixed canvas,
   fixed callbacks, fixed capabilities, hard budgets.

Avoid untrusted GDScript / `.tscn` / Godot `Expression` for public packs. That
crosses the existing raw-load-art-only content-pack boundary and gives too much
host access unless a separate security decision explicitly accepts that risk.

## Open Questions

- Should public packs ever be allowed to ship code, or should code-backed
  activities remain first-party / trusted-plugin only?
- If a script VM is added, should the language be MiniScript/Wren-like, a custom
  GDScript-written interpreter, or a declarative grid/activity DSL first?
- What are the first three real minigames to prototype? Recommendation:
  blackjack, a QTE lockpick, and a PuzzleScript-style grid puzzle because they
  stress different parts of the API. Initial specs:
  [`minigame_activity_type_initial_specs_2026-06-28.md`](minigame_activity_type_initial_specs_2026-06-28.md).
- Should online play treat activities as local-only presentation with bounded
  result validation, or should activity inputs/results enter deterministic logs?
