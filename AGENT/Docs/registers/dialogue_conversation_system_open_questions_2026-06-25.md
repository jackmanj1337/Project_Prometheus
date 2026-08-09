---
Type: register
Status: RESOLVED 2026-06-25q
Last verified: 2026-06-30
Register: DLG-1..14
Resolved-in: 2026-06-25q (DLG-1..13) / 2026-06-25r (DLG-14 branch gating via F16); all RESOLVED — rotation a build-time investigate
---

# Dialogue / Conversation System (Foundation F15) — End-User Shape + Data Format + Open Questions

> **Amended 2026-07-27 by `[DRC-7..9]`:** V1 conversations are wholly atomic. The player may Save
> during dialogue, but the save contains only the preceding committed checkpoint and loading restarts
> the conversation. `[DLG-11]`'s entry-boundary `conversation_resume`/`visited_trail` persistence is
> superseded for V1 and reserved only for the post-v1 explicit-checkpoint design. All other useful
> entry-id/history guidance remains authoring/presentation guidance, not a V1 save contract.
>
> **Amended 2026-08-09 by `[DLUX-1..16]`:** this register's full-screen stage-over-chat-log verdict
> is retained as historical evidence for an optional rich presenter, not the definition or V1 floor
> of dialogue. V1 requires a compact presenter and adds only a bounded rich cue set: portrait
> enter/exit/expression, named position, simple horizontal move, idempotent left/right facing flip,
> deterministic portrait layer, background, music/SFX request, and simple fade/slide. `[DLG-9]`'s
> live reflection/copy system, arbitrary transforms, scene filters, and general compositor remain
> deferred behind a separate cutscene-stage port. Dialogue history is now a record type in the
> unified chapter combat-log/`MapLedger` Rewind menu, not a dialogue-local competing timeline. The
> accepted packet is
> [`dialogue_ux_comparative_research_and_questions_2026-08-09.md`](../design/dialogue_ux_comparative_research_and_questions_2026-08-09.md).

**Started:** 2026-06-25q (fleshes the F15 rough end-shape pinned in `[RCV-1]`).
**Status:** **[DLG-1..14] RESOLVED** (DLG-1..13 2026-06-25q incl. reflect DLG-9; **DLG-14 branch gating
via the shared `[REQ]`/F16 Requirement system 2026-06-25r**). Rotation feasibility = the one build-time
investigate. Foundation **F15**.
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
  transparency **|** an authored `special-bg` raw-loaded asset) + **stage elements** (positioned,
  animated per DLG-3) composited by an **explicit layer system** (DLG-12). A **stage element** is any
  animated entity — a speaker's portrait is the common case, but it **need not be a speaker or a
  person** (DLG-13 decouples the stage from dialogue).
- **Chat-log region** = a **script-style** running log (`SPEAKER: text`), scrollable for read-back;
  the current line appends.
- **One renderer:** the only difference between a battle one-liner and a story scene is the background
  layer (map-transparent vs special-bg). Collapses the old "in-map box vs scene view" fork.
- **Resolution:** RESOLVED 2026-06-25q — stage of layered **stage elements** over a background, above a
  script-log; element/layer model in DLG-12/DLG-13.

### [DLG-2] Data format — a flat, addressable entry list  **[RESOLVED]**
A **Conversation** = `{ id, entries: Array }` of **forward-compatible, addressable** entries (extends
the `[RCV-1]` line/choice/command reservation):
- **`line`** = `{ speaker: <unit_id | named-speaker key>, text: <F13 key>, cues?: [<effect-cue>] }`
  (cues = DLG-3 effects fired with the line).
- **`choice`** = `{ prompt?: <F13 key>, options: [{ label: <F13 key>, goto?: <label>,
  set_flag?: <flag> }] }` (DLG-5).
- **`command`** = a **scene op** (`set_background: map|<bg>`, stage-element `enter`/`exit`/`move`/
  `set_layer`, a DLG-3 effect, camera) **or** a **MET action** (e.g. `grant_item` mid-scene). Stage
  elements are addressed by a **stable element id** independent of any speaker (DLG-13).
- **`label`** = a jump target (choices/branches address it).
- **Background as a `command`** (not a per-line field) is what lets the scene change mid-conversation.
  Branching = `label` + `goto`. Names/text/labels are **F13 keys, never concatenated.**
- Plain data (Dictionary array or Resource) the runtime reads and a tool emits (DLG-8).
- **Resolution:** RESOLVED 2026-06-25q — entries reference stage elements by stable id; layer ops are
  commands (DLG-12).

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
  > **v1 slice content (build decision, owner 2026-06-30)** — the `B4-DIALOGUE-V1`
  > slice = entry types `line`/`choice`(`goto`+`set_flag`)/`label`; commands
  > `set_background: map|<bg>` + **positioned static portraits** (`enter` at a
  > location / `move` / `exit` / replace) + a MET passthrough
  > (`set_var`/`flag`, `grant_item`, recruit hook); `[REQ]`/F16 gating at
  > **option + conversation** scope (per-option `hidden|shown_disabled`); manual
  > pacing; **atomic playback**. **Deferred:** the `[DLG-3]` animation/effect
  > tiers, `[DLG-9]` reflect, `[DLG-4]` auto/skip pacing, camera, scene filters,
  > runtime `[DLG-12]` `set_layer`, `[DLG-11]` mid-conversation suspend, and the
  > `[DLG-8]` editor. Full detail in
  > [`band4_implementation_plan_handoff_2026-06-30.md`](../plans/band4_implementation_plan_handoff_2026-06-30.md).

### [DLG-8] Authoring — plain data now + a dedicated editor later  **[RESOLVED]**
The format is **plain data** (Dictionary/Resource the runtime reads); **simple linear conversations are
hand-authorable** in the interim. The viewing richness (layered animation, branching, scene/camera
commands, pacing) makes hand-writing complex conversations painful, so a **dedicated conversation
editor** (timeline/node, **emits the same plain data**) is pinned as the eventual tool — the
**dialogue-specific answer to the deferred 4a–4e "GUI editor vs hand-JSON"** authoring question.
- **Resolution:** RESOLVED 2026-06-25q — plain-data format now; dedicated editor pinned as the tool.

### [DLG-9] The **reflect effect** — design + interaction matrix  **[RESOLVED 2026-06-25q (rotation = build-time investigate)]**
**Walked 2026-06-25q.** Reflect = a **mirror-across-an-axis** operation with **two modes** (owner):
- **`in_place`** — mirror the stage element across an axis **in place, no duplicate**. Primary intent:
  **flip a character's facing** (turn to face the other way) **without a separate asset**. (Generalizes
  DLG-3(B) `flip` to an arbitrary axis.)
- **`copy`** — render a **mirrored duplicate** at an offset (a character looking at their reflection in
  a mirror / pool). Original stays; the copy is a second instance.
- **Scope:** **both per-element and scene-wide** (a per-element reflection AND a scene-wide reflective
  plane, e.g. a wet floor mirroring the whole stage).
- **Render: LIVE** — the reflection continuously mirrors the source's **current composited state**, so
  expression (A), transforms (B), and scene filters (C) appear in it automatically.
- **Parameters (full set):** axis (horizontal-below / vertical-beside / **arbitrary angle**), opacity,
  offset/gap, distortion/ripple, fade; the reflection (copy) has **its own layer** (DLG-12, default
  behind the source) and can itself be targeted by B transforms. **Rotation of the reflection** =
  supported in principle via the arbitrary-angle axis + a B `rotate`; **flagged "look into" at build**
  (perf/asset feasibility) — the one residual investigate, not a design hole.

**The unifying rule that resolves the matrix — a fixed per-element pipeline, re-applied live each frame:**
> `source asset → (A) expression → (B) transforms (flip/move/scale/rotate) → reflect (mirror ± copy) →
> layer composite (DLG-12) → (C) scene-wide filters`

**Interaction matrix (reflect × …), LIVE:**
- **× (A) expression** — propagates automatically; the reflection shows the current expression. No
  conflict.
- **× (B) flip** — both are mirrors → **may cancel or compound.** `in_place` reflect across the **same
  axis** as a `flip` = **net identity (no-op)** — define explicitly; across **different** axes = compose
  (h-flip + v-reflect = 180° turn). This is the headline edge case.
- **× (B) move/scale/rotate** — applied **before** reflect in the pipeline, so the reflection mirrors
  the moved/scaled/rotated element live; a `copy` reflection's position = `mirror(source pos)` across
  the axis, updated live.
- **× (C) scene filters (rain/fog/flashback)** — C is scene-wide and applies **after/over** reflect, so
  the reflection (and a scene-wide reflective plane) gets the rain/fog wash too. A scene-wide reflective
  plane reflects the **filtered** scene (rain shows in the water — intuitive). **Edge:** during a
  full-scene **flashback wavy-transition**, a scene-wide reflect reflects a distorting scene — **suspend
  scene-wide reflection for the duration of a full-scene transition** (perf + visual sanity).
- **× reflect (double-reflect)** — `in_place` across the same axis twice = identity (composes as a
  transform); **`copy` recursion is capped at depth 1** (a reflective plane does **not** reflect another
  reflective plane) to avoid infinite/expensive recursion.
- **Resolution:** RESOLVED 2026-06-25q — two-mode (`in_place|copy`) live mirror, both scopes, full
  params; the fixed pipeline-order rule + the cancellation/recursion/transition edges above resolve the
  interaction matrix. Rotation feasibility is the only build-time investigate.

### [DLG-10] F1 / save reservations (authoring vs persisted)  **[RESOLVED — amended by DLG-11]**
- Conversation data, effect cues, character expression/animation sets, backgrounds = **authoring, not
  saved.** Player pacing preference = **settings**, not save.
- **Branch state persists via F6 flags** (DLG-5) — already reserved. One-time conversations played as a
  `once:true` MET event action ride `map_events_fired` (`[MET-5]`); reserve `conversations_seen` only
  if conversations become directly invokable outside an event latch (the `[RCV-6]` flag, unchanged).
- **For an atomic (run-to-completion) conversation, no new save field is needed.** **Mid-conversation
  suspend is a separate reservation — see [DLG-11].** (This item originally claimed "no new save field";
  DLG-11 amends it for the suspend-mid-conversation case.)
- **Resolution:** RESOLVED 2026-06-25q — atomic playback needs no new field; mid-conversation → DLG-11.

### [DLG-11] Mid-conversation save / "between speaker" suspend  **[RESOLVED]**
**Superseded for V1 by `[DRC-7..9]` (2026-07-27).** The design below is retained as evidence for the
post-v1 checkpoint option; it must not be implemented as automatic per-line persistence.
**Owner ask (2026-06-25q):** support suspending **mid-conversation** ("between speaker" saves) — track
the conversation history + who last finished a line. **The entry-list format (DLG-2) supports this
very well**, because entries are an **ordered, addressable list**:
- **Save granularity = entry boundaries ("between speaker")** — a save point sits **after a `line`
  entry completes, before the next entry begins** (owner's framing). **No mid-typewriter state** is
  ever serialized (no character-position cursor, no in-flight tween) — the renderer resumes by
  re-presenting the current line settled.
- **Resume state is tiny:** `conversation_resume = { conversation_id, cursor }`, where `cursor` is the
  **stable entry id / index** of the resume point. **"Who last finished their line" is DERIVED**
  (`entries[cursor].speaker`) — not stored separately.
- **Chat-log history:**
  - **Linear conversation** → the log is **replay-derivable** from the immutable authored `entries`
    up to `cursor` (the prefix `entries[0..cursor]` filtered to `line`s). **Nothing to store.**
  - **Branching conversation** (DLG-5 `choice`/`goto`) → the traversed path is **not** a simple
    prefix, so persist a **`visited_trail`** = the ordered list of entry ids actually shown. It both
    reconstructs the log AND records which branch was taken. Branch-set flags also persist in F6
    (redundant safety / for cross-conversation reads).
- **Format constraint this imposes:** entries need **stable addresses** (a stable id or a stable
  authored index) so a `cursor`/`visited_trail` survives — a small requirement the DLG-8 editor honors.
- **Ties:** this is a **suspend-save** concern (L1 `SaveManager`/`SaveData` + the `[MET-8]` deferred
  runner — a playing `dialogue` action becomes part of the suspend snapshot). A mid-conversation
  **hard save** (not just suspend) is allowed by the same state; whether the campaign *permits* saving
  mid-conversation is a campaign-rules policy, not a format limit.
- **F1 reservation (supersedes DLG-10's "no new field"):** a `conversation_resume` block in the
  suspend/save snapshot = `{ conversation_id, cursor, visited_trail? }`.
- **Resolution:** RESOLVED 2026-06-25q — entry-boundary ("between speaker") granularity; tiny
  `{conversation_id, cursor}` resume; log replay-derivable (linear) or via a `visited_trail`
  (branching); last-speaker derived; requires stable entry addresses; reserves `conversation_resume`.

### [DLG-12] Explicit layer / z-order system  **[RESOLVED]**
**Owner ask (2026-06-25q):** "who stands in front of who" must be **explicit and changeable.** Every
**stage element** (DLG-13) **and** every effect carries an **explicit layer (z-index)**; compositing
is by that order, not by insertion/spawn order. A **`set_layer`** command (DLG-2) reorders an element
at runtime (a character steps forward; the reflection copy sits behind by default). The background is
the bottom layer; scene-wide (C) filters/reflective planes declare their own layer band so authors can
place a fog/reflection above or below specific elements.
- **Resolution:** RESOLVED 2026-06-25q — explicit per-element + per-effect z-index; `set_layer`
  command; deterministic, author-controlled compositing.

### [DLG-13] Stage / speaker decoupling — "stage elements", not "portraits"  **[RESOLVED]**
**Owner ask (2026-06-25q):** don't tie the stage to dialogue/speakers — the system must be able to
render an **animated entity that has no lines** (or isn't a person). So the stage holds **stage
elements** (any animated entity, addressed by a **stable element id**); **"speaker" is a role** a
`line` references, and a speaker *may* resolve to a stage element — but stage elements **exist
independently** of lines. Consequences: DLG-3 effects, DLG-9 reflect, and DLG-12 layers all operate on
**stage elements** (not "portraits"); a conversation can drive a purely visual/animated scene with zero
`line` entries (commands only). The script-log speaker labels (DLG-6) still resolve via F13, but that is
a *log* concern, separate from the *stage*.
- **Resolution:** RESOLVED 2026-06-25q — stage elements (animated entities) are first-class and
  speaker-independent; portraits are the common case, not the model.

### [DLG-14] Branch gating via the shared Requirement system (F16)  **[RESOLVED]**
**Owner ask (2026-06-25r):** make branch paths available based on flags / unit ids / class level /
proficiency / stat / skill / item-location / etc. **These are NOT dialogue-specific** → dialogue reuses
the shared **`[REQ]` Requirement/Predicate foundation (F16)**, not a private condition language.
- **Gating granularity (owner): option + segment + whole conversation.** A `Requirement` may gate (a) a
  single `choice` **option**, (b) a labeled **segment**, and (c) a **whole conversation** (a
  precondition). **Reconcile (c):** when a conversation is launched by a MET trigger, the launching
  `condition` (now a Requirement, `[REQ-8]`) already gates eligibility — **don't duplicate**; a
  conversation-level `requires` is the convenience for **direct** (non-MET) invocation.
- **Subject (owner: both modes):** dialogue supplies `speaker`/`participant:<role>` as the natural
  subjects, and also allows `unit:<id>`/`party` (`[REQ-3]`).
- **Gated-out option UX (owner: author's choice per option):** an option is **`hidden`** (secret path)
  **or** **`shown_disabled`** with its rendered requirement (`[REQ-5]` → "[Requires: Lockpick]") —
  mirrors `[VIL-6]`/`[VIL-7]` transparency-vs-secrecy. Per-option.
- **History interplay:** branch taken is recorded by the `[DLG-11]` `visited_trail` (resume) + any
  `choice` `set_flag` to `[F6]` (persistent) — gating predicates read those plus live unit/party state.
- **Resolution:** RESOLVED 2026-06-25r — dialogue gating = `[REQ]`/F16 Requirements at option/segment/
  conversation scope; subject per `[REQ-3]`; gated-out = per-option hidden|shown_disabled.

---

## Cross-references
- **Branch gating** (`[DLG-14]`) consumes the shared **`[REQ]` Requirement system (F16)** — flags, unit
  id, class/proficiency/stat level, skill/trait, item held/equipped/convoy.
- Supersedes the rough F15 end-shape in **`[RCV-1]`** (which now points here); shared consumers:
  recruit (`[RCV]`), village (`[VIL-4]`), support (`[REL-6]` `unlock_conversation`), main-character
  name-sub (`[MCH]`), story scenes.
- Consumes: **F13** (`[MCH-6]` text indirection), the campaign-pack **raw-load art pipeline**, the
  **MET** `dialogue` action + `once` latch, the **F6** two-scope flag store.
- **DLG-9 (reflect effect)** resolved 2026-06-25q (two-mode live mirror + interaction matrix); the only
  residual is a **build-time rotation feasibility investigate**.
- **DLG-12/DLG-13** generalize the stage: explicit layers + speaker-independent **stage elements** (the
  system can render animated non-speaking entities), so DLG-3/DLG-9/DLG-12 operate on stage elements.
