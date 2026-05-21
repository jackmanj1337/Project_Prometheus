# Feasibility Review — Four-Faction Armies + Hotseat Manual Control

Status: **Discussion / planning only. No code changed.**
Date: 2026-05-17
Originating question: *How hard would it be to replace the enemy/ally phase with
direct control from a second player?*

Confirmed design intent (from the 2026-05-17 discussion):

- The game is planned around **four armies**: **blue** (player), **red** (enemy),
  **green** (allied to blue, AI-controlled, fights red), and **yellow** (a fourth
  army that fights blue, green, *and* red).
- **Any non-blue army** may be assigned to a **hotseat slot** for manual human
  control instead of AI. Blue is always human (player 1).

This review covers what the codebase assumes today, the gap to that design, and a
staged roadmap.

---

## 1. Short answer

The four-faction system is a **real structural change** — the whole game currently
assumes exactly two sides. But it decomposes into a clean sequence of mostly
behaviour-neutral refactors, and the **hotseat part is the smallest piece**: once
factions and a hostility model exist, "human controls this faction" is just routing
that faction's phase through the existing `MapCursor` instead of the AI.

Rough order of magnitude: **a multi-PR effort, ~2–3 weeks of focused work**, of
which hotseat itself is the last ~2–3 days. The phase system already separates
*phase orchestration* (`TurnManager`) from *who acts* (`EnemyAI` vs `MapCursor`) —
that seam is what makes this tractable.

---

## 2. How the system works today

### Turn cycle (`TurnManager.gd`)
Only **two** phases exist (`GameState.Phase.PLAYER`, `.ENEMY`):
```
start_map → start_player_phase
          → end_player_phase     (player presses End Turn)
          → start_enemy_phase    → await EnemyAI.run_enemy_phase(...)
          → start_player_phase   → ... loop
```

### The key seam — `TurnManager.start_enemy_phase()` (lines 114–127)
```gdscript
var ai := get_node_or_null("/root/EnemyAI")
if ai:
    await ai.run_enemy_phase(_grid, self)
else:
    call_deferred("start_player_phase")
```
A phase is **one awaited call**. Whatever runs it just has to act on that side's
units and return; `TurnManager` then advances. This is where AI vs. human plugs in.

### Player control — `MapCursor.gd`
`MapCursor` is the input receiver (`Node2D` with `_unhandled_input`), owning an FSM
(`FREE → UNIT_SELECTED → UNIT_MOVED → TARGETING`, plus `LOCKED`) and three
`RefCounted` slices: `MapCursorSelection`, `MapCursorTargeting`, `MapCursorInput`.
It auto-locks for the enemy phase via `_on_phase_changed`.

### AI control — `EnemyAI.gd`
`run_enemy_phase` loops `gs.get_living_enemy_units()` and resolves each unit's move
+ combat directly through `CombatResolver` — it never touches `MapCursor`. AI and
human are two independent control paths onto the same units.

### Teams
`Unit.team` is just a string, `"player"` or `"enemy"`. `GameState` buckets every
unit into `_player_units` or `_enemy_units`. **There is no green/yellow, and no
concept of a faction being allied to another.**

---

## 3. The gap — three things the codebase does not have

### 3.1 More than two teams
`GameState` has exactly two unit buckets and two living-unit filters; `Phase` has
two values; the turn cycle is a hardcoded player↔enemy ping-pong.

### 3.2 A hostility model
Today "hostile" *is* "the other team" — a binary. With four armies that breaks:
green and blue must not fight each other, while yellow fights everyone.

The described relationships:

|        | blue | red  | green | yellow |
|--------|------|------|-------|--------|
| blue   |  —   | foe  | ally  | foe    |
| red    | foe  |  —   | foe   | foe    |
| green  | ally | foe  |  —    | foe    |
| yellow | foe  | foe  | foe   |  —     |

This is captured exactly by **alliance groups**: `{blue, green}`, `{red}`,
`{yellow}` — two units are hostile iff they are in different groups. Simpler than a
full pairwise matrix and it covers every case above. (A full matrix is the fallback
*only* if you ever need asymmetric or neutral/non-aggression relations — none are
needed for the stated design.) Recommend the alliance-group model.

Once it exists, "attackable" and "healable" stop meaning "enemy/player team" and
start meaning "hostile group / same group" — `GridManager.gd:331` already does the
same-team test relatively (`target.team == unit.team`); the rest must follow suit.

### 3.3 A per-faction controller assignment
Each faction needs a controller. Blue is fixed to human. Red/green/yellow are each
independently assignable. A small config — e.g. `GameState` holds
`{red: AI, green: AI, yellow: HOTSEAT}` — set per map or per match. The phase
routine reads it to decide how to run that faction's phase.

Treat the controller type as an **open enum**, even though only two values ship
first: `AI`, `HOTSEAT`, and a later `REMOTE` (LAN / online — see §5 stage 8). Each
type is just a different implementation of the same "run this faction's phase and
return when done" contract — the `start_enemy_phase` seam (§2) already has exactly
that shape, so adding `REMOTE` later does not disturb `AI` or `HOTSEAT`.

---

## 4. The `"player"` hardcoding (blocks human control of any other faction)

`MapCursor` and its slices assume the controlled side is the literal `"player"`.
For a human to drive *red* (or green/yellow) units with the same UI, each of these
must become *"the faction currently in control"*:

| File / line | Hardcoded assumption | Effect |
|---|---|---|
| `MapCursorSelection.gd:33` | `unit.team != "player"` → reject | Cannot select a non-player unit at all |
| `MapCursorTargeting.gd:52` | `get_attackable_enemies_from_tile` | "Attackable" defined relative to the player side |
| `MapCursorTargeting.gd:113,138` | `target.team == "player"` | Accepts/rejects the wrong side as a target |
| `TurnManager.gd:96` | resets only `u.team == "player"` to `READY` | Other factions never get a fresh `READY` state |
| `TurnManager.gd:150` | `are_all_player_units_done()` | End-Turn gate counts only player units |
| `CombatResolver.gd:72` | `is_player_initiated = attacker.team == "player"` | Combat bonus keyed to a literal team |
| `MapCursor._on_phase_changed` | locks the cursor on `ENEMY` | A human-controlled non-blue phase would lock its own cursor |

This is mechanical, not deep — but spread across ~6 files. The clean fix is one
"active controlling faction" concept threaded through `MapCursor.setup` and its
slices, replacing every literal `"player"`.

---

## 5. Staged implementation roadmap

> **Now milestoned.** This work is split across three milestones in
> `GDD_updates.md`: stages 1–4 + content are **Milestone 14 — Faction System**;
> stages 6 & 8 are **Milestone 15 — Hotseat & Remote Control**; the objective
> overhaul in §6 is **Milestone 16 — Objective System**. This document remains the
> detailed design behind all three.

Each stage is a separate PR. Stages 1–2 are behaviour-neutral and fully covered by
the existing 347-test suite, which de-risks everything after.

1. **`"player"` → faction-relative** (no behaviour change). Replace literal team
   comparisons (§4) with an "active faction" concept. Suite stays green.
2. **Hostility model** — add the alliance-group helper; rewrite "attackable /
   healable / blocks movement" in `GridManager`, `MapCursorTargeting`, `EnemyAI` to
   query it. Still two factions, so still behaviour-neutral.
3. **N-faction core, data-driven.** Define a faction as **data**, not a code enum —
   a faction list / resource carrying `id`, display colour, and alliance group.
   `GameState` gains per-faction unit buckets + `get_living_units_of(faction)`;
   `Phase` becomes an index into a turn-order list; `TurnManager` drives an
   arbitrary-length cycle. The turn order is a configurable per-map list,
   **defaulting to `blue → green → red → yellow`**. Building this data-driven from
   the start is what makes a 5th+ faction cheap later — see §9.
4. **`EnemyAI` → faction-agnostic AI** — `run_enemy_phase` becomes
   `run_ai_phase(faction)`, targeting *all hostile units* via the hostility model
   rather than `get_living_player_units()`. The scoring helpers (`_find_nearest`,
   `_choose_move_tile`) are already team-agnostic once fed the right target set.
   Confirmed AI direction: the AI does **not** prefer a target by which faction it
   belongs to — every hostile unit is an equal candidate, ranked by *combat*
   factors: target HP / strength, terrain danger of the approach, and a priority
   bump for units flagged objective-critical (a unit whose death is a blue defeat
   condition — readable from the §6 objective data). This is a scoring upgrade over
   today's pick-nearest and can be layered on after the basic faction-agnostic
   retarget lands.
5. **Per-faction controller assignment** — the AI/hotseat config (§3.3); each
   faction's phase routes to `run_ai_phase` or to a hotseat `MapCursor`.
6. **Hotseat routing — the initial shipping target.** When a faction is HOTSEAT,
   its phase `await`s a `MapCursor` driving that faction's units (cursor not
   locked, End-Turn ends the phase). One phase at a time, shared screen, turns
   alternate. Small once 1–5 land. *Optional polish:* per-phase keybindings —
   give each hotseat slot its own `InputMap` action set (`p2_cursor_up`, …) and
   tell `MapCursorInput` which set to read. Because phases alternate rather than
   run at once, shared keys already work; separate bindings are a convenience, not
   a requirement.
7. **Content + UX** — green/yellow spawns on maps, faction colours/banners, an
   "Army N" / hotseat-slot label.
8. **(Future milestone) Remote play** — LAN, later online. A `REMOTE` controller
   (§3.3) whose phase `await`s a remote player's committed actions instead of a
   local `MapCursor`. The phase-boundary seam makes the *hook* easy; the *work* is
   networking proper — state sync, command relay, replaying the other side's move
   animations locally, latency/disconnect handling. A milestone of its own, not a
   tail of this one. Keeping the controller abstraction clean in stages 5–6 is
   what keeps it cheap to add.

---

## 6. Victory & defeat

> **Milestoned as M16 — Objective System** in `GDD_updates.md`. This section is its
> design rationale; the milestone carries the actionable checklist.
>
> **SUPERSEDED 2026-05-17 (Decision 8, `AGENT/Docs/design_decisions_log_2026-05-17.md`).**
> The blue-centric framing below was reversed: victory/defeat is now evaluated
> **per aggression group**, with per-group victory + defeat conditions and a
> ranked-standings results screen. Blue-centric left red/yellow with no win state,
> which breaks online PvP. The multi-condition objective design below still holds —
> only the "blue only" scoping changed. See `GDD_updates.md` M16 for the current
> spec.

Original (superseded): *win/loss is always evaluated for the blue team only — the
other armies have no independent win state. This simplifies the faction work —
green and yellow need unit buckets, phases, AI, and a controller, but* not *victory
tracking.*

What it *does* need is a richer **per-map objective system** — a separate workstream
from the faction/control plumbing, but they meet here. Today `MapData` carries a
single `objective_type` (only `"rout"` implemented), a `turn_limit`, and
`required_survivor_ids`; `TurnManager.check_victory_conditions` hardcodes those.
The maps described need objectives expressed as **lists of typed conditions**,
blue-centric, e.g.:

- **Rout** of a specific faction — or of *several* (`rout red AND rout yellow`).
- **Defeat boss(es)** — one or more named unit ids (the "two bosses" map).
- **Seize** — one or more tiles (the "two castles" map).
- **Escape** — named units must reach an escape tile/zone (incl. *green* units —
  "certain green units must escape").
- **Survive / defend** — last N turns, or hold a tile for N turns.
- **Defeat conditions** — blue routed, a `required_survivor` died (incl. *green*
  units — "particular green units dying"), turn limit exceeded, seize-tile lost.

Recommended shape: `MapData` holds a `victory_conditions` and a
`defeat_conditions` array of small condition resources; `check_victory_conditions`
becomes a generic evaluator (AND across victory conditions, OR across defeat).
This generalises cleanly and a green unit id simply appears in a survive/escape
condition like any other — no special-casing the faction.

This objective overhaul can land **before, after, or alongside** the faction work;
it only shares the `MapData` / `check_victory_conditions` touch-points.

---

## 7. Decisions & remaining questions

**Settled:**
- **Turn order** — configurable per map, default `blue → green → red → yellow`.
- **Victory/defeat** — per aggression group (§6, updated by Decision 8 — was
  blue-centric only).
- **AI targeting** — faction-blind; ranks hostile units by HP / strength / terrain
  danger / objective-criticality, not by which army they are (§5 stage 4).

**Resolved 2026-05-17** (see `AGENT/Docs/design_decisions_log_2026-05-17.md`):
- **Empty factions.** Turn cycle skips a 0-unit faction (confirmed). HUD: a
  faction never in the map is hidden; a faction that was present but is now wiped
  shows greyed-out / "eliminated" (Decision 2).
- **Hotseat keybindings.** Later polish — ship the first hotseat build with shared
  keys (functional because phases alternate); add per-phase `InputMap` action
  sets afterward if wanted (Decision 6).

---

## 8. GDD note

`Unit.team` is documented in `GDD_01_Architecture.md:591` as `"player" | "enemy"`.
This will need GDD updates — at minimum `GDD_01` (team model + controller types),
`GDD_06` (maps/objectives — the multi-condition objective system in §6), and
`GDD_08` (enemy AI → faction AI + hostility). Worth dedicated GDD sections once the
design above is confirmed.

---

## 9. After this is done — how hard is a 5th (or 6th…) faction?

This is the payoff of building stage 3 **data-driven**. If a faction is a data
entry rather than a hardcoded enum value, adding one is:

**An AI-controlled extra faction — pure data, no code, no new tests.** The map
designer:
1. Defines the faction (`id`, display colour, alliance group, `controller = AI`).
2. Adds it to that map's turn-order list.
3. Tags the relevant units onto it and places their spawns.

That's it. The turn cycle is already arbitrary-length, the AI is already
faction-agnostic and scores any hostile unit (§5 stage 4), and the hostility model
just reads the alliance group — so no system needs new code to handle one more
army. The work is entirely in the map's `MapData` and unit data.

**A hotseat-controlled extra faction — data, plus one config step.** Same as above
with `controller = HOTSEAT`, **plus** a hotseat slot. If per-phase keybindings
(§5 stage 6) are in use, a new slot needs its own `InputMap` action set in
`project.godot` — a config edit, not GDScript. With shared keys it stays pure data.

**What keeps it that cheap — design rules to honour in stages 3 & 7:**
- Faction `id` is a string/data value; never a `match` over a fixed enum.
- Faction colour and banner label are *read from* faction data, not hardcoded per
  army — so a new faction renders correctly with no UI code.
- Alliance membership is declared by the faction (a group name); a new faction
  either joins an existing group or forms its own (hostile to all).
- `MapData` exposes faction list, turn order, and per-unit faction as
  inspector-editable fields — that *is* the map designer's tooling.

**The cost of getting stage 3 wrong:** if factions ship as a fixed four-value enum,
every new faction is instead a code change touching `GameState` buckets, the
`Phase` enum, the turn cycle, the AI, and the UI — and a round of tests. The
data-driven approach front-loads a little design effort to make all later factions
free; it is strongly recommended.

**Practical caveats even when done right:** an 8-faction map is legal but each
faction adds a phase per round (pacing, not performance); and UI real estate —
phase banner, turn-order display — should be built to list N factions, not assume
four.

---

## 10. Impact on the planned milestones (M8–M13)

Good news first: **nothing in the faction work conflicts with or blocks a planned
milestone.** It removes no mechanic and rewrites no spec. But two of its pieces are
*foundations* that M8–M10 would otherwise each reinvent — so this is a **sequencing**
question, not a collision.

### 10.1 The hostility model is a shared foundation (M8, M9, M10)
Faction stage 2 replaces the player/enemy binary with the alliance-group hostility
model (§3.2). Several planned systems are specced in terms of "ally" and "enemy":
- **M9 aura skills** (Charm, Daunt, Anathema, Motivate) buff "allies" / debuff
  "enemies" in a radius.
- **M9 reactive skills** — `on_ally_attacked` (Parry, Redirect).
- **M10 Canto / Special Dance** target an "adjacent ally."
- **M8 poison weapon** applies a condition to "an enemy" that was hit.

Today "ally" = same team, "enemy" = the other team. With four armies that is wrong
(a blue Daunt must not debuff green; a yellow Canto targets yellow allies). Each of
these must resolve ally/enemy through the hostility model.
→ **Sequencing call, not a conflict.** If stage 2 lands before M9/M10, every skill
is written correctly once. If M9/M10 land first against the binary, the faction
work then has to revisit each skill. **Recommend stage 2 before M9.**

### 10.2 The controller abstraction is shared with M10
M10's `grant_extra_turn` reactivates a unit mid-phase and, per its spec, "re-locks
the MapCursor" — which assumes cursor == player. During a hotseat non-blue phase an
extra turn must be driven by *that faction's* controller; during an AI phase, by
the AI (an enemy Galeforce/Encore unit). Both M10 and hotseat depend on one
"who controls this unit right now" abstraction (faction stage 5).
→ If `grant_extra_turn` is written controller-agnostic — re-enter the *active
controller*, not "the cursor" — M10 and hotseat compose for free. If M10 hardcodes
the cursor, hotseat revisits it later.

### 10.3 `is_player_initiated` in the combat context
`CombatResolver` tags each combat `is_player_initiated` (line 72). In a red-vs-yellow
fight that label is meaningless. M9 combat skills read the combat context —
generalise this to `is_initiator` / attacker-faction in faction stage 1, before M9
keys any skill off it.

### 10.4 Low / no interaction
- **M8 conditions** — applied and ticked per *unit*, not per team; the only
  team-aware point is "who may poison whom," covered by 10.1. Otherwise orthogonal.
- **M12 Laguz** — the shift gauge is per-unit; "gain per turn" ticks inside
  `_begin_phase` for the active faction. Faction-agnostic; no conflict.
- **M11 / M13 content** — pure data. M11 maps would actively *want* the faction
  system to place green/yellow armies — synergy, not conflict. The objective-system
  overhaul (§6) is likewise a natural fit for M11's new maps.

### 10.5 Net recommendation
Slot the faction refactor's **stages 1–3** (un-hardcode `"player"`, hostility model,
N-faction core) **before M9**. They are behaviour-neutral and guarded by the
existing 347-test suite, and they stop M9/M10 skill content from being written
against a binary that is about to change. **M8** can land before or after — it
barely touches teams. The **hotseat / remote stages (6, 8)** can come whenever;
they gate no milestone.
