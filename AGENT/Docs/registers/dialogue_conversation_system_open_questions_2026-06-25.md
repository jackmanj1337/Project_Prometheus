---
Type: register
Status: OPEN 2026-06-25q
Last verified: 2026-06-25
Register: DLG-1..10
Resolved-in: 2026-06-25q (DLG-1..8,10 RESOLVED; DLG-9 reflect-effect OPEN by design)
---

# Dialogue / Conversation System (Foundation F15) — End-User Shape + Data Format + Open Questions

**Started:** 2026-06-25q (fleshes the F15 rough end-shape pinned in `[RCV-1]`).
**Status:** **[DLG-1..8,10] RESOLVED 2026-06-25q**; **[DLG-9] (the "reflect effect") OPEN by design** —
the owner asked to *flag* it for its own design pass, not resolve it now. Foundation **F15**.
**Scope of this pass:** define the **end-user (viewing) shape** of a conversation, then read off the
**data-format** and **authoring-tool** consequences (owner's stated goal). **Build is staged** (DLG-7):
the format + renderer reserve the full vision; the first build is a slice. `[RCV-1]` pinned the rough
shape; this register is the authoritative F15 design.

**Method (owner pref `feedback_feature_walk_end_shape_first`):** end-user shape via questions first,
then derive data/tool. Owner calls (2026-06-25q): presentation = **one overlay, scene-region (top,
layered background = map-transparent | special-bg + portraits) over a script-style chat-log (bottom)**;
speakers = **script-style labels + portrait animations synced to advance (loop | play-once-hold)**;
choices = **designed into the viewing now**; pacing = **author offers manual / skip-to-decision /
auto-advance**; effects = **three tiers (character / portrait-transform / scene-wide) + a flagged
"reflect effect"**; build = **staged (v1 slice + full reserved)**; authoring = **plain data now +
dedicated editor later**.

**Code grounding:** **no dialogue system exists** (verified 2026-06-25o). Consumes F13 text
indirection (`[MCH-6]`: ID-keyed text + `unit_id` name lookup, `tr()` when localized), the campaign-
pack **raw-load art pipeline** (portraits/backgrounds; `project_art_pipeline_licensing`), MCH avatar
portraits (`[MCH]`), the MET `dialogue` action + `once` latch, and the F6 flag store (branch state).

---

## Verdict (the end-user shape)

> **One full-screen overlay, two regions, one renderer.** A conversation is a **scene region (top)** —
> a *layered stage* whose **background layer** is either the **live tactical map (toggleable
> transparency)** or an **authored special background**, with **animated portraits layered on top** —
> above a **script-style chat-log region (bottom)** (scrollable `SPEAKER: line` history). Because the
> background can BE the map, "battle one-liner" and "story scene" are the **same overlay** with a
> different background layer — **no second renderer.** The viewing richness pushes the **data format**
> to a flat, addressable **entry list** (`line`/`choice`/`command`/`label`) and pushes **authoring**
> toward a **dedicated editor emitting plain data**.

---

## Register

### [DLG-1] Unified overlay — end-user presentation  **[RESOLVED]**
One full-screen overlay = **scene region (top)** + **chat-log region (bottom)**.
- **Scene region** = a layered stage: a **background layer** (`map` shown through a toggleable
  transparency **|** an authored `special-bg` raw-loaded asset) + a **portrait layer** (positioned
  slots, active-speaker emphasis, animated per DLG-3).
- **Chat-log region** = a **script-style** running log (`SPEAKER: text`), scrollable for read-back;
  the current line appends.
- **One renderer:** the only difference between a battle one-liner and a story scene is the background
  layer (map-transparent vs special-bg). Collapses the old "in-map box vs scene view" fork.
- **Resolution:** RESOLVED 2026-06-25q.

### [DLG-2] Data format — a flat, addressable entry list  **[RESOLVED]**
A **Conversation** = `{ id, entries: Array }` of **forward-compatible, addressable** entries (extends
the `[RCV-1]` line/choice/command reservation):
- **`line`** = `{ speaker: <unit_id | named-speaker key>, text: <F13 key>, cues?: [<effect-cue>] }`
  (cues = DLG-3 effects fired with the line).
- **`choice`** = `{ prompt?: <F13 key>, options: [{ label: <F13 key>, goto?: <label>,
  set_flag?: <flag> }] }` (DLG-5).
- **`command`** = a **scene op** (`set_background: map|<bg>`, portrait `enter`/`exit`/`move`, a DLG-3
  effect, camera) **or** a **MET action** (e.g. `grant_item` mid-scene).
- **`label`** = a jump target (choices/branches address it).
- **Background as a `command`** (not a per-line field) is what lets the scene change mid-conversation.
  Branching = `label` + `goto`. Names/text/labels are **F13 keys, never concatenated.**
- Plain data (Dictionary array or Resource) the runtime reads and a tool emits (DLG-8).
- **Resolution:** RESOLVED 2026-06-25q.

### [DLG-3] Effect / animation taxonomy — three tiers  **[RESOLVED]**
Effects/animations span **three scopes**, each parameterized and carrying a **playback mode**,
composable (B layers on a portrait, C over the whole scene). **Playback modes:**
- **`loop`** — loop indefinitely until the conversation advances.
- **`once`** — play once, then hold the final frame until advanced.
- **`loop_until <condition>`** — loop until a condition; the **canonical case = until the line's text
  finishes scrolling** (a mouth-flap that runs while the typewriter reveal plays, then stops). The
  condition is parameterized (text-reveal-complete is the headline; duration / named cue are later
  extensions).
- **(A) Character effects** — per-character portrait **expression** changes (tied to a character's
  expression/animation asset set; DLG-6).
- **(B) Portrait transforms** — **generic, layer on ANY portrait**: **flip/mirror** (a simple
  inversion, *not* a separate flipped asset), **move/translate** (reposition around the scene),
  scale, etc.
- **(C) Scene-wide effects/filters** — applied across the scene region: **rain**, **fog drifting over
  characters**, a **wavy flashback transition**, colour/filter washes.
- Authored as `command` entries or per-`line` `cues`. The vocabulary is **author-extensible** (new
  effect ids add without format change), mirroring the F4/F5 profile philosophy.
- **Effect parameters include a `speed`** (playback rate) — per-effect, optional. Consider **also** a
  **global player-facing animation-speed setting** (accessibility / preference; pairs with the DLG-4
  pacing modes). *(Owner addition 2026-06-25q, "possibly" — pinned as a parameter; the global setting
  is a soft reserve.)*
- **Resolution:** RESOLVED 2026-06-25q — three-tier (character / portrait-transform / scene) effect
  model, each with `loop | once | loop_until<condition>` playback (the `loop_until` headline =
  loop-until-text-finishes-scrolling, i.e. mouth-flap while talking), composable.

### [DLG-4] Player controls / pacing — author-configurable  **[RESOLVED]**
All three modes exist; the author declares which are offered + the default:
- **Manual** — tap to advance (typewriter reveal; tap again completes the line instantly).
- **Skip-to-next-decision** — fast-forward to the next `choice` point (stops there).
- **Auto-advance** — timed; optional per-line dwell hint for author pacing control.
- **Resolution:** RESOLVED 2026-06-25q — manual / skip-to-decision / auto, author-configured.

### [DLG-5] Branching choices — first-class, designed in now  **[RESOLVED]**
A `choice` entry presents options; selecting one **sets a flag (F6)** and/or **jumps to a `label`** —
route splits, recruit yes/no, support outcomes. "Skip-to-next-decision" (DLG-4) halts here. Integrates
the recruit conversation branching (`[RCV]`) and the F6 two-scope flags.
- **Resolution:** RESOLVED 2026-06-25q — choices = options→{set_flag | goto label}; designed now,
  build per DLG-7.

### [DLG-6] Speakers + assets (F13 + art pipeline)  **[RESOLVED]**
**Script-style name labels** resolve via **F13** (`unit_id` name-lookup for roster/MCH speakers; a
**named-speaker key** for non-roster voices). **Portraits + special backgrounds** are **raw-loaded
campaign-pack assets** (the established art pipeline; MCH avatar portraits ride this). A character
carries an **expression/animation set** the DLG-3(A) cues select from.
- **Resolution:** RESOLVED 2026-06-25q.

### [DLG-7] Build staging — v1 slice, full reserved  **[RESOLVED]**
The **format + renderer reserve the full vision** (animated portraits, three effect tiers, branching,
map/special-bg layers, all pacing modes). The **first build is a slice** — e.g. static portraits +
linear advance + manual pacing over the map-or-bg background layer — so dialogue **ships with
recruit/village** without the whole VN system. Later tiers/branching/auto/skip **layer in without
replacing authored data** (the owner's "useful foundation, not replaced" intent). Exact v1 slice
content is a build-time call.
- **Resolution:** RESOLVED 2026-06-25q — staged; v1 slice subset, full end-shape reserved.

### [DLG-8] Authoring — plain data now + a dedicated editor later  **[RESOLVED]**
The format is **plain data** (Dictionary/Resource the runtime reads); **simple linear conversations are
hand-authorable** in the interim. The viewing richness (layered animation, branching, scene/camera
commands, pacing) makes hand-writing complex conversations painful, so a **dedicated conversation
editor** (timeline/node, **emits the same plain data**) is pinned as the eventual tool — the
**dialogue-specific answer to the deferred 4a–4e "GUI editor vs hand-JSON"** authoring question.
- **Resolution:** RESOLVED 2026-06-25q — plain-data format now; dedicated editor pinned as the tool.

### [DLG-9] The **"reflect effect"** — flagged design TODO  **[OPEN — by design]**
**Side note (owner ask 2026-06-25q): design a "reflect effect" as its own pass.** It is an effect
defined chiefly by its **interaction matrix** — *how it actually interacts with each other effect
type* (DLG-3 A character-expression, B portrait-transforms like flip/move/scale, C scene filters like
rain/fog/flashback-transition) **and all the edge cases** (e.g. reflect + flip, reflect + move, reflect
under a scene filter, reflect during a flashback transition, reflect + reflect). *(Working
interpretation: a reflection/mirror visual of a portrait or the scene — to be confirmed when designed.)*
**Not resolved now** — recorded so it is not lost.
- **Status:** OPEN — needs a dedicated design pass producing the reflect × {A,B,C} interaction table +
  edge-case rules + parameters.

### [DLG-10] F1 / save reservations  **[RESOLVED]**
- Conversation data, effect cues, character expression/animation sets, backgrounds = **authoring, not
  saved.** Player pacing preference = **settings**, not save.
- **Branch state persists via F6 flags** (DLG-5) — already reserved. One-time conversations played as a
  `once:true` MET event action ride `map_events_fired` (`[MET-5]`); reserve `conversations_seen` only
  if conversations become directly invokable outside an event latch (the `[RCV-6]` flag, unchanged).
- **No new save field** beyond the F6/MET reservations.
- **Resolution:** RESOLVED 2026-06-25q.

---

## Cross-references
- Supersedes the rough F15 end-shape in **`[RCV-1]`** (which now points here); shared consumers:
  recruit (`[RCV]`), village (`[VIL-4]`), support (`[REL-6]` `unlock_conversation`), main-character
  name-sub (`[MCH]`), story scenes.
- Consumes: **F13** (`[MCH-6]` text indirection), the campaign-pack **raw-load art pipeline**, the
  **MET** `dialogue` action + `once` latch, the **F6** two-scope flag store.
- **DLG-9 (reflect effect)** is the one OPEN item — its own design pass.
