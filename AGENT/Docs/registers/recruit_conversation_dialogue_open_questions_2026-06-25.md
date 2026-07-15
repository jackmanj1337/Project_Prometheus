---
Type: register
Status: RESOLVED 2026-06-25o
Last verified: 2026-06-25
Register: RCV-1..6
Resolved-in: 2026-06-25o
---

# Recruit Conversation Side (#4 ⇄ A3, A4) + the shared Dialogue-System foundation (F15) — Player-Facing Design + Open Questions

**Started:** 2026-06-25o (second A4 sub-cluster, after Village `[VIL]`).
**Status:** [RCV-1..6] **RESOLVED 2026-06-25o** (end-shape-first walk; all owner calls taken).
**A4 — Story / event-driven map content.** This pass firms the **conversation / event side of
recruitment** against the `[RCR-3]` MET-action contract, and — because the `dialogue` action needs a
conversation system that does not exist — pins a **rough forward end-shape for a Dialogue/Conversation
system as new foundation F15** (build deferred, hooks forward-compatible) so what we build now isn't
thrown away. The **roster side is settled in `[RCR-1..7]` and is NOT relitigated here.**

**Method (owner pref `feedback_feature_walk_end_shape_first`):** end-shape via questions first.
Owner calls (2026-06-25o): dialogue = **"pin a rough plan so we build a useful foundation, not
something to be replaced"** (design the end-shape, defer the full build); talk direction = **author's
choice per recruit** (directed | symmetric); damage-forfeit = **author-composed MET condition only**
(no built-in rule).

**Source:** `[RCR-3]`/`[RCR-4]` A4 hand-off contract (the `talk` trigger + `recruit`/`dialogue`
actions + the "don't kill before recruiting" condition); the `[VIL-2]` interactive-trigger keystone
(2026-06-25n) the `talk` trigger is a config of; F13's deferred "dialogue-data format" gap (`[MCH-6]`).

**Code grounding:** **No dialogue/conversation system exists** (no `scripts/` match; no spec doc) —
F13 (`[MCH-6]`) is the only related layer and its enforcement was explicitly "deferred until the
dialogue-data format exists." `Unit.team` faction flip is the `recruit()` substrate (`[RCR-1]`). The
`talk` action is a unit-targeted entry on the `[VIL-2]`/`TileActions` interactive substrate. MET
(`[MET-1..9]`) owns the trigger→action runner + `once` latch + flag store.

---

## Verdict

> **The recruit conversation side is thin** — a `talk` config of the `[VIL-2]` interactive-trigger
> substrate + a `recruit` MET action calling the `[RCR-3]` API + author-composed conditions. **The one
> substantial new thing is the Dialogue/Conversation system, and it isn't recruit-specific** — it's a
> shared foundation (recruit · village `[VIL-4]` · support `[REL-6]` · main-character name-sub `[MCH]`
> · story scenes). Pin its **rough end-shape as F15** now (forward-compatible data format + the
> `dialogue` MET action hook); defer the presentation build.

---

## Register

### [RCV-1] Dialogue/Conversation system = new foundation **F15** (rough end-shape; build deferred)  **[RESOLVED]**
A **conversation** is an id-referenced authored asset that the **`dialogue` MET action** plays by
`conversation_id`. Format = an ordered list of **forward-compatible entries**, each an `line` (v1) |
`choice` (reserved) | `command` (reserved):
- **`line`** (v1 build slice) = `{ speaker: <unit_id | named-speaker key>, text: <F13 text-key>,
  portrait/expression: optional, side: optional left|right }`. **Text is an F13 key — never
  concatenated** (reuses F13: ID-keyed templates + `unit_id` name lookup + Godot `tr()` when
  localized).
- **`choice`** (reserved, later) = present player options → each option sets a flag / jumps to a
  label. The branching-narrative hook (Three Houses style).
- **`command`** (reserved, later) = run a MET action mid-scene (e.g. `grant_item`, `flag`) so a
  conversation can *do* things, not just speak.
- **Presentation deferred:** the textbox / portrait rendering is a later build; **the data format +
  the `dialogue` action hook are the foundation** committed now. The entry-list-of-tagged-entries
  shape means adding `choice`/`command` later **does not break** line-only v1 data.
- **Shared consumers:** recruit (this register), village (`[VIL-4]` `dialogue` action), support
  conversations (`[REL-6]` `unlock_conversation`), main-character name substitution (`[MCH]`), general
  story scenes. This realizes F13's deferred "dialogue-data format."
- **Resolution:** RESOLVED 2026-06-25o — pin the rough end-shape as **F15** (🔶 not fully firmed —
  ratify the v1 line schema + reserved choice/command shape in the define-all sweep before F1).
- **FLESHED 2026-06-25q → see `[DLG-1..10]`** (`registers/dialogue_conversation_system_open_questions_2026-06-25.md`).
  The F15 end-user shape (unified overlay: layered scene over a script-style chat-log), the entry-list
  data format, a three-tier effect taxonomy (character / portrait-transform / scene-wide), branching
  choices, author-configurable pacing, staged build, and the plain-data-now + dedicated-editor-later
  authoring call are now firmed there. One OPEN item: the **"reflect effect"** design TODO (`[DLG-9]`).

### [RCV-2] `talk` trigger = a config of the `[VIL-2]` interactive-trigger substrate  **[RESOLVED]**
The `talk` trigger is the **unit-targeted** sibling of village `Visit`: the acting unit selects a
"Talk" action-menu entry (gated through `TileActions` like Seize/Escape/Visit) on an adjacent valid
target → fires the MET `talk` trigger carrying the **pair** (actor + target). Reuses the `[VIL-2]`
substrate wholesale — **does NOT re-invent a trigger.** Firing-conditions (recruiter present, required
flags, etc.) ride MET's condition system + F6 per `[RCR-4]`.
- **Resolution:** RESOLVED 2026-06-25o — `talk` = a `[VIL-2]` config (unit-targeted); reuse, not new.

### [RCV-3] Talk directionality = author's choice per recruit  **[RESOLVED]**
A per-trigger flag selects:
- **`directed`** — the authored recruiter (a specific unit / tag, per `[RCR-4]`) must be the **actor**
  who chooses Talk; classic FE. The condition keys on *who acted*.
- **`symmetric`** — **either** party may initiate; the condition checks the *pair*, not the actor.
- **Resolution:** RESOLVED 2026-06-25o — author's choice per recruit (`directed | symmetric`).

### [RCV-4] `recruit` MET action = calls the `[RCR-3]` API; trigger-agnostic  **[RESOLVED]**
The `recruit` action calls the firmed `recruit(unit)` transition API (`[RCR-1]` faction flip →
persistent roster + `[RCR-2]` `recruited:<id>` flag), and may chain a `dialogue` (RCV-1) and extra
`flag`s. It is **trigger-agnostic** — runnable from **any** MET trigger (`talk`, village `Visit`
`[VIL]`, `turn_reached`, `flag`), with `talk` the canonical interactive case (so "village hides a
recruitable unit" / "ally joins on turn 5" work for free). The `capture` action is the twin (`[RCR-3]`)
but its **carry/jail mechanic stays A2**; the combat non-lethal path is `[STY-6]` (A1).
- **Resolution:** RESOLVED 2026-06-25o — one trigger-agnostic `recruit` action over the `[RCR-3]` API.

### [RCV-5] Damage-forfeit = author-composed MET condition only (no built-in rule)  **[RESOLVED]**
"Must not have attacked the recruiter" is **one MET condition** an author may compose over the existing
condition system + F6 — **not** a baked engine rule, and **no** per-unit `was_attacked_by_player` flag
is added to the engine. Keeps recruitment free of hard-coded rules (consistent with `[RCR-4]`'s
firing-conditions-on-the-trigger split). A convenience helper condition can be added later **without**
an engine rule.
- **Resolution:** RESOLVED 2026-06-25o — author-composed condition only; no built-in forfeit.

### [RCV-6] F1 / save reservations  **[RESOLVED]**
- Already reserved (`[RCR-7]`): recruited-unit roster membership + `recruited:<id>` flags + unit
  eligibility/reward fields.
- **Dialogue replay:** a one-time conversation played as an action of a `once:true` MET event is
  already latched by the **event's** `map_events_fired` (`[MET-5]`) — **no new field** while dialogue
  fires only via MET actions. **Reserve `conversations_seen`** (a fired-set sibling) *only if*
  conversations become directly invokable outside an event latch — flagged, not added.
- **Authoring (not save):** the conversation data (RCV-1), the per-recruit directionality flag
  (RCV-3), and recruit-trigger conditions (RCV-5).
- **Resolution:** RESOLVED 2026-06-25o — no new save field beyond `[RCR-7]`; `conversations_seen`
  flagged-on-demand.

---

## Cross-references
- Consumes: `[RCR-1..7]` (roster recruit/capture API + recruited-state — **not relitigated**),
  `[VIL-2]` (interactive-trigger substrate), `[MET-1..9]` (runner/conditions/flags/`once`), F13
  (`[MCH-6]` text indirection).
- **F15 (dialogue) is shared by:** recruit (here), village `[VIL-4]`, support `[REL-6]`
  (`unlock_conversation`), main-character name-sub `[MCH]`, story scenes.
- Capture: combat non-lethal `[STY-6]` (A1) + carry/jail (A2); roster end-state `[RCR-5]`.
