> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# LAN & Online Multiplayer — Decision Log — opened 2026-05-17

Status: **COMPLETE 2026-05-17.** All 20 multiplayer decisions (D1-D20) + the Steam
precondition ratified, plus 6 non-multiplayer decisions (M14/M15/M16 open
questions + next-session sequencing). Companion to
`second_player_control_feasibility.md` and `GDD_updates.md` M14-M16. These
supersede the *recommendations* in `online_play_design_decisions.md` as the
ratified design.

## Summary — all decisions ratified
| # | Decision |
|---|----------|
| Steam | Undecided — build swappable (high-level API discipline) |
| D1 | Host-authoritative client-server |
| D2 | Per-action streaming |
| D3 | Host rolls all RNG |
| D4 | Full authoritative snapshot each phase |
| D5 | Host runs all AI |
| D6 | Independent animation + bounded phase barrier |
| D7 | Godot high-level multiplayer API over ENet (swappable foundation) |
| D8 | Direct + punch-through, relay fallback |
| D9 | Lobby codes + friend invites (direct IP for LAN) |
| D10 | Strict exact-version match |
| D11 | Hash-check parity (host-push deferred, data-only + sandboxed loader) |
| D12 | Host assigns all factions; blue free, not host-locked |
| D13 | Host configures, clients ready-up |
| D14 | Pause + reconnect window; AI sub or save-and-continue; no host migration |
| D15 | Optional per-phase timer, default off/generous |
| D16 | No cross-session resume in v1 |
| D17 | No spectators in v1 |
| D18 | Host validates every command |
| D19 | No fog of war in v1 online |
| D20 | Authored armies (builder/draft = future expansions) |

## Summary — non-multiplayer decisions
| # | Decision |
|---|----------|
| 1 | Next session = playtest first, then decide build direction |
| 2 | M14 empty-faction HUD: distinguish never-present (hidden) vs wiped (greyed) |
| 3 | M16: confirm the 7-type condition list as-is |
| 4 | M16 seize: dedicated Seize action (ActionMenu entry), not passive occupation |
| 5 | M16 escape: zone (set of tiles), units removed-on-entry |
| 6 | M15 per-phase keybindings: later polish, ship hotseat with shared keys |
| 7 | Victory checking: hybrid (phase-boundary sweep + event-driven + round counter) |
| 8 | Per-group victory/defeat (not blue-centric); ranked-standings results screen |
| 9 | Per-map activation_mode (WHOLE_PHASE/ALTERNATING), default WHOLE_PHASE |
| 10 | Revised order: M14(1-3) → M16 → M14(4-5) → M8 → M9 → M10 → M11 → M12 → M13 |

---

Note: the next-session sequencing question (M14 vs M16 vs maps) was set aside in
favour of this multiplayer walkthrough — revisit it afterwards.

LAN-step decisions: D1, D2, D3, D4, D5, D6, D7, D12, D13, D18, D20, basic D14.
Online-step decisions: D8, D9, D10, D11, D15, D16, D17, D19, full D14.

---

## Precondition — Is the game shipping on Steam?
- *Status:* DECIDED 2026-05-17
- *Decision:* **Undecided — build swappable.** Build all netcode against Godot's
  high-level multiplayer API so the transport stays swappable. Deferring the
  Steam/off-Steam call carries no penalty *provided* netcode is never written
  against raw ENet calls. Swapping to Steam later: gameplay netcode untouched;
  cost = add GodotSteam (build-pipeline), swap the peer, rewrite the
  connection/lobby UI layer, Steamworks setup + $100 Steam Direct fee.

## D1 — Synchronization & authority model  [LAN] — KEYSTONE
- *Status:* DECIDED 2026-05-17
- *Decision:* **(b) Host-authoritative client-server.** One player hosts and owns
  the truth; validates and broadcasts. Settles D3/D4/D5/D18 downstream.

## D7 — Transport library  [LAN]
- *Status:* DECIDED 2026-05-17
- *Decision:* **(a) Godot high-level multiplayer API over ENet** as the swappable
  build-time foundation. Covers all of LAN directly. The online transport
  (Steam vs. relay) is deferred and slots underneath the same API later.

## D20 — Army source for non-blue factions  [LAN]
- *Status:* DECIDED 2026-05-17
- *Decision:* **Default = authored armies (a-variant).** Blue uses its own army
  (campaign roster / host's army); the **non-blue factions are defined by the map
  or campaign creator**. Bring-your-own-army (b) and draft (c) are kept open and
  recorded as **possible future expansions**, not v1 scope.
- *Note:* the user phrased blue as "the host." Reconciled at D12: that is the
  typical/default case, not a hard lock — the host assigns all factions including
  blue, and blue is assignable to any peer.

## D2 — Command model & granularity  [LAN]
- *Status:* DECIDED 2026-05-17
- *Decision:* **(b) Per-action streaming.** Each unit's finalised move+action is
  sent the moment it is committed; opponent watches the phase unfold live. Same
  command objects as batch. M15 Part A's hotseat controller should emit these
  committed command objects from day one — the LAN command layer for free.

## D14 — Disconnect / reconnection policy  [LAN basic / Online full]
- *Status:* DECIDED 2026-05-17
- *Decision:* **(b) Pause + reconnect window.** On a drop: pause and offer a
  reconnect window (~60-120s, host-configurable). On expiry, the choice is
  **AI substitution** (resumable if the player returns) **or save-and-continue-
  later** (suspend save). **No host migration** — a host drop ends the match to
  a suspend save. Leans on the Phase 3 mid-battle suspend-save feature.

## D4 — State reconciliation / desync safety net  [LAN]
- *Status:* DECIDED 2026-05-17
- *Decision:* **(c) Full authoritative snapshot each phase** for v1. Commands
  stream live for presentation; the per-phase snapshot is the truth, so any
  client glitch self-heals within one phase.
- *Upgrade note:* (c) is a clean foundation for a later (b) hash-check upgrade —
  the full-snapshot serialize/apply path IS (b)'s recovery branch. The only
  deferred cost of upgrading is hardening client-side command-apply to
  authoritative quality; worth it only if bandwidth ever constrains (it won't
  for turn-based).

## D3 — Combat RNG authority  [LAN]
- *Status:* DECIDED 2026-05-17
- *Decision:* **(a) Host rolls all RNG**; outcomes ride along in the authoritative
  broadcast. Forced by D1(b).

## D5 — AI execution location  [LAN]
- *Status:* DECIDED 2026-05-17
- *Decision:* **(a) Host runs all AI factions**, broadcasting resulting commands +
  snapshot. One source of truth. Forced by D1(b).

## D6 — Animation / presentation pacing  [LAN]
- *Status:* DECIDED 2026-05-17
- *Decision:* **(b2) Independent animation + bounded phase barrier.** Each client
  animates from the command stream at its own pace; the host waits a short capped
  grace (~1-2s, or until clients ack phase-animations-done, whichever first)
  before signalling the next phase. A slow client fast-forwards/skips queued
  animations to catch up. Plus a local-only skip/fast-animation toggle. Avoids
  both the slow-client stall and jarring phase overlap.

## D12 — Faction-to-peer assignment  [LAN]
- *Status:* DECIDED 2026-05-17
- *Decision:* **(a) Host assigns, blue free.** The host assigns all four factions
  — including blue — to a connected peer or to AI in the lobby. One peer may own
  multiple factions. No mid-match reassignment except via the D14 disconnect path.
  Blue is **not** locked to the host (doc's original draft stands).
- *Reconciles D20:* "blue is the host" is the typical/default case, **not** a hard
  lock — blue is assignable to any peer.

## D13 — Lobby / match config ownership  [LAN]
- *Status:* DECIDED 2026-05-17
- *Decision:* **(a) Host configures, clients ready-up.** Host picks map, rules
  (permadeath / leveling method), and faction assignment; clients confirm ready.

## D18 — Cheat prevention / trust model  [LAN]
- *Status:* DECIDED 2026-05-17
- *Decision:* **(b) Host validates every command** — unit ownership, legal move,
  legal target, range, action legality — before applying. Catches bugs and casual
  cheating. Adversarial anti-cheat (c) deferred unless ranked online ships.

## D8 — NAT traversal  [Online]
- *Status:* DECIDED 2026-05-17
- *Decision:* Direct connect + punch-through first, with a relay as guaranteed
  fallback. Free if Steam transport is later chosen; a pure-ENet online release
  needs a self-hosted relay.

## D9 — Session discovery / matchmaking  [Online]
- *Status:* DECIDED 2026-05-17
- *Decision:* v1 = lobby codes + friend invites. Direct-IP entry kept for the LAN
  stage. Full quickplay/ranked matchmaking is post-launch only.

## D10 — Version / protocol compatibility  [Online]
- *Status:* DECIDED 2026-05-17
- *Decision:* Strict exact-version match on a protocol-version number, with a
  clear "version mismatch" message.

## D11 — Content parity  [Online]
- *Status:* DECIDED 2026-05-17
- *Decision:* (a) Ship-content-only + content-hash check; reject a mismatch.
  Host-pushing content (b) is recorded as a **later feature, data + assets only,
  never scripts/behaviour, and gated on a sandboxed safe-loader** (a pushed
  `.tres` loaded via the default ResourceLoader is RCE). Custom behaviour must be
  pre-installed by both peers, never runtime-pushed. Recommended distribution for
  custom maps: out-of-band (e.g. Steam Workshop) + hash-check parity.

## D15 — Turn timer / pacing  [Online]
- *Status:* DECIDED 2026-05-17
- *Decision:* Optional per-phase timer, default off or generous. A timeout feeds
  D14's AFK branch. Chess-clock is a later ranked-mode nicety.

## D16 — In-match save / cross-session resume  [Online]
- *Status:* DECIDED 2026-05-17
- *Decision:* (a) v1 = no cross-session resume; in-session reconnect only (D14).
  Full resume rides on the mid-battle suspend-save landing first.

## D17 — Spectators  [Online]
- *Status:* DECIDED 2026-05-17
- *Decision:* (a) None in v1. Host-authority + per-phase snapshot (D1b/D4c) keeps
  spectators a cheap later addition — nothing precludes it.

## D19 — Fog of war / hidden information  [Online]
- *Status:* DECIDED 2026-05-17
- *Decision:* (a) v1 online ships without fog. Per-client state filtering is a
  real cost; tackle it only when fog itself ships, as an explicit "online + fog"
  combined feature. D4's snapshot design should leave room for per-client
  filtering later.

---

# Remaining decisions (non-multiplayer)

Open questions from the Session J notes addendum + the next-session sequencing.

## Decision 1 — Next-session work / sequencing
- *Status:* DECIDED 2026-05-17
- *Decision:* **Playtest first, then decide.** Next session = manually verify the
  untested map-menu / end-turn path in-game (M key, confirm/cancel on an empty
  tile, left/right click on an empty tile), then choose the build direction
  (M14 stages 1-3 vs M16 vs maps 002-005). The build-direction call is deferred
  until after that playtest. Standing recommendation when revisited: M14 stages
  1-3 first (keystone for M9 sequencing and the ratified M15 multiplayer work).

## Decision 2 — M14 empty-faction HUD behaviour
- *Status:* DECIDED 2026-05-17
- *Decision:* **Distinguish the two cases.** A faction never in the map's
  turn-order list does not appear in the HUD at all. A faction that *was* in the
  turn order but has lost all its units shows **greyed-out / "eliminated"** in the
  turn-order display. Requires tracking "was ever populated" per faction. The turn
  cycle skipping a 0-unit faction is already confirmed (feasibility §7).

## Decision 3 — M16 objective condition-type list
- *Status:* DECIDED 2026-05-17
- *Decision:* **Confirm the 7-type list as-is:** `rout`, `defeat_boss`, `seize`,
  `escape`, `survive`, `protect`/`unit_survives`, `turn_limit`. Covers all planned
  maps (002-005 and classic objectives). `defend` is folded into `survive`;
  `recruit`/`talk` is out of scope (a unit-interaction, not a victory condition).
  New types are cheap to add later — a typed resource + one evaluator branch.

## Decision 4 — M16 seize semantics
- *Status:* DECIDED 2026-05-17
- *Decision:* **Dedicated Seize action.** A blue unit on a seize tile claims it
  via a "Seize" entry in the `ActionMenu`, gated by "on a seize tile" AND "this
  unit may seize." Deliberate, genre-authentic, supports restricting who may
  seize. The `seize` condition resource carries the tile id(s) and an **optional
  allowed-unit-id list** (empty = any blue unit).
- *GDD action:* update the M16 draft — `seize` is "a Seize action used on the
  tile," not passive occupation. Add a Seize entry to the `ActionMenu`.

## Decision 5 — M16 escape: tile vs. zone
- *Status:* DECIDED 2026-05-17 — auto-fire reversed 2026-05-20 (see addendum)
- *Decision:* **Zone (a set of tiles).** An `escape` condition defines a region /
  edge / doorway (inspector-editable tile list or rect); a named unit escapes by
  reaching any tile in it. Generalizes single-tile (a zone of size 1), no
  bottleneck, models edge-escape. A named unit that reaches the zone is **removed
  from the map** ("escaped") — automatic on entry (no Escape action needed;
  escape rarely needs Seize-style timing). Condition met when all named units
  have escaped.
- *Addendum 2026-05-20 (post-M16 code review, H-1):* the auto-fire-on-entry half
  of this decision is REVERSED. Escape is now a deliberate `ActionMenu` entry,
  same shape as Seize (Decision 4) — the player picks Escape from the menu and
  the turn commits. Reason: the auto-fire path ran inside the `bus.unit_moved`
  signal handler, which fires from inside the cursor's `await move_along_path`.
  `record_escape` queue_free'd the unit, but the cursor flow then resumed and
  showed an ActionMenu for the freed unit (and `set_unit_state(DONE)` re-inserted
  it into `_unit_states`). Making Escape a deliberate menu entry has no mid-move
  ownership-of-the-unit problem. The zone semantics (a set of tiles) are
  unchanged — `can_escape(unit, tile)` gates the button on the unit being named
  and the current tile being in the zone.

## Decision 6 — M15 per-phase keybindings timing
- *Status:* DECIDED 2026-05-17
- *Decision:* **Later polish.** The first hotseat build ships with shared keys —
  fully functional because phases alternate (only one faction acts at a time).
  Per-phase `InputMap` action sets are deferred and added later if playtesting
  shows players want distinct controls. Keeps M15 Part A lean.

## Decision 7 — Victory checking in the N-faction turn cycle
- *Status:* DECIDED 2026-05-17
- *Context:* the `blue→green→red→yellow` cycle replaces the 2-phase
  player↔enemy ping-pong. Today `check_victory_conditions()` is called from
  `_on_unit_died` (event-driven) and `start_player_phase()` (turn-limit).
- *Decision:* **Hybrid trigger model.** Victory checking is decoupled from phase
  *count*:
  1. **Phase-boundary sweep** — full evaluator runs at the start of every
     faction's phase. The catch-all; nothing slips through a round.
  2. **Event-driven immediacy** — also evaluated right after a death, a Seize
     action (Decision 4), and an escape (Decision 5), so a win/loss registers the
     instant it becomes true rather than at the next phase boundary.
  3. **Round-counter conditions** (`turn_limit`, `survive` N turns) read
     `turn_number`, which increments **once per round** (cycle wrap) — not per
     phase. The turn-limit check moves off `start_player_phase` to the round
     boundary.
- *Required structural changes:*
  - `turn_number` increments once per round, not per phase.
  - The N-faction `TurnManager.advance_to_next_phase()` checks `_map_over` at the
    top and **halts the cycle** — one chokepoint replacing today's per-
    `start_X_phase` guard.
  - Controllers (AI phase loop, hotseat `MapCursor`) check `_map_over` between
    units and **abort early** so a decided map does not keep playing out
    remaining phases.
  - `_map_over` latch retained (double-emit guard + cycle-halt flag).
  - Evaluator is phase-/faction-agnostic — it reads named conditions against
    current state regardless of whose phase is active. (Per-group scope: see
    Decision 8, which supersedes the original blue-centric framing.)

## Decision 8 — Per-group victory/defeat (decouple from blue-centric)
- *Status:* DECIDED 2026-05-17
- *Supersedes:* feasibility doc §6 "win/loss is always evaluated for the blue
  team only" — that predates the ratified multiplayer plan.
- *Rationale:* blue-centric leaves red/yellow with **no win state**, which breaks
  online PvP (D20 preset armies, M15 Part B) — every human-controlled group needs
  a real win/lose state.
- *Decision:* victory/defeat is evaluated **per aggression group**
  (`{blue,green}`, `{red}`, `{yellow}`, …), not for blue alone.
  - **Model:** per-group `victory_conditions` + `defeat_conditions` (M16's
    two-array model generalized from "blue" to "per group"). `rout`/`seize`
    author naturally as a group's *defeat*; `escape`/`survive` as the achiever's
    *victory*. All 7 condition types stay natural.
  - **Defaults:** a group with no conditions gets an implicit defeat condition —
    group routed (all its units dead). Every group always has a way to be out.
  - **Win resolution:** meeting a victory condition wins the map for that group;
    meeting a defeat condition eliminates that group; the map also ends when ≤1
    group remains (last standing wins). All remaining groups out at once → draw.
  - **Results screen:** **ranked standings** — winner first, losing groups
    ordered by elimination round (1st/2nd/3rd/4th placement); draw shown in the
    top slot. Requires an "eliminated on round N" field per group. Shown by
    default at map end. The player is always blue, so the screen still leads with
    a clear Victory/Defeat from blue's group's standpoint, then the standings.
- *Impact:*
  - The Decision 7 hybrid evaluator loops per group instead of running once.
  - `MapData` carries per-group condition sets, not a single blue pair.
  - Moderate M16 scope increase; the aggression-group model already exists from
    M14 stage 2, so this is a generalization, not new machinery.
  - AI: objective-seeking AI (a group rushing its own seize/escape) is a separate
    later concern — for v1 AI fights and elimination covers its "win."

## Decision 9 — Per-map activation model (whole-phase vs alternating)
- *Status:* DECIDED 2026-05-17
- *Context:* question of switching from FE-style I-Go-You-Go (a faction moves all
  its units, then the next) to alternating activation (each army activates one
  unit, round-robin, until all have acted, then the round counter advances and
  all units refresh).
- *Key insight:* I-Go-You-Go is a **special case** of an activation scheduler — a
  scheduling policy that exhausts one army before advancing. So build **one**
  activation-based engine with a pluggable "who activates next?" policy, not two
  systems.
- *Decision:* **Per-map `activation_mode` setting**, `WHOLE_PHASE | ALTERNATING`,
  **default `WHOLE_PHASE`**. The activation engine's primitive is
  `activate_one_unit(faction)`; whole-phase mode loops it for one army,
  alternating mode advances army after each unit. Default whole-phase keeps the
  FE-style baseline and all existing M14/M15/M16 specs + content valid;
  alternating is opt-in per map (or per campaign).
- *Required structure:*
  - M14 stage 3 builds an **activation scheduler** with the policy abstraction —
    not a fixed phase cycle. (This *replaces* stage 3's "Phase = index into a
    turn-order list" framing; the turn-order list is reused as phase order in
    whole-phase mode / round-robin order in alternating mode.)
  - Player controller branches on mode: whole-phase keeps "End Turn" + returns
    control on End-Turn/all-done; alternating returns control after one committed
    unit.
  - `_begin_phase` (fort healing, Renewal, turn-modifier tick) timing is
    mode-aware: army-phase start in whole-phase, round start in alternating.
  - Double orchestration test coverage.
- *Caveat:* every future turn-coupled mechanic (e.g. M10 `grant_extra_turn`) must
  work under both modes — features should query the scheduler, not assume a
  model. Ongoing discipline cost, not a one-time one.
- *Timing:* decide-before-M14 — M14 stage 3 builds exactly this; deciding now
  makes it a substitution of effort, not a later rewrite.
- *Compatibility:* Decision 7 (victory checking) already decoupled from phase
  count — "phase-boundary sweep" → "activation-boundary sweep", no conflict.
  Online D2 per-action streaming syncs each activation as a command in either
  mode.

## Decision 10 — Revised milestone implementation order
- *Status:* DECIDED 2026-05-17
- *Context:* a dependency audit of the M8-M16 roadmap against Decisions 7-9
  surfaced five dependencies the roadmap did not account for.
- *Findings (dependencies the old roadmap missed):*
  1. **M16 is no longer independent of M14.** Decision 8 (per-group victory)
     makes M16 depend on M14's aggression-group model (stage 2), per-faction unit
     buckets (stage 3), and the activation scheduler (stage 3, for Decision 7's
     activation-boundary sweep). The old "M16 independent of M14" is false.
  2. **M10 depends on M14 stages 1-5**, not just "before M9." Decision 9 makes
     `grant_extra_turn` an extra *activation* (needs the stage-3 scheduler) that
     re-enters the active controller (needs stage-5 controller abstraction).
  3. **M8 condition ticking interacts with the activation model.** "Start of
     holder's turn" must tick per-unit-*activation* (well-defined in both
     activation modes) — so M8 lands after M14 stage 3, or is built per-activation.
  4. **M14 stage 4's AI objective-criticality scoring depends on M16** (it reads
     objective data). Resolved by ordering: M14 1-3 → M16 → M14 stage 4 bump.
  5. **Doc staleness:** the Phase 3 mid-battle suspend save must serialize
     activation-scheduler state, not "current phase"; M15 Part A's "one phase at a
     time" wording is stale; the M16 "independent of M14" note is stale.
- *Decision — revised order:*
  **M14 stages 1-3 → M16 → M14 stages 4-5 (+content) → M8 → M9 → M10 → M11 →
  M12 → M13 → Phase 3.**
  - M14 stages 1-3 are behaviour-neutral and test-guarded (default `WHOLE_PHASE`,
    still 2 factions) — the lowest-risk foundation; do them first.
  - M16 next, while the stage-3 scheduler/victory code is fresh.
  - M14 stages 4-5 complete the faction core (stage 4's objective-criticality
    bump now reads M16 data). Alternative: do M14 1-5 as one block, backfill just
    the objective-criticality bump after M16.
  - M15 Part A (hotseat) gates nothing — slot anytime after M14 stage 5.
  - M14 green/yellow content + Maps 002-005 ride after M16.
  - M15 Part B + remaining Phase 3 stay deferred; move the mid-battle suspend
    save adjacent to M15 Part B (D14 save-and-continue depends on it).

---

## Addendum - 2026-06-11 GDD Alignment Decisions

### A1 - Tactical AI scoring
- *Status:* DEFERRED TO A SEPARATE TASK.
- *Decision:* M14's faction architecture, controller dispatch, and faction
  content remain complete. HP/strength/terrain/objective-critical target scoring
  is tracked as a separate tactical-AI improvement and does not reopen the
  faction-system milestone.

### A2 - Hotseat CLI/dev override
- *Status:* DEFERRED.
- *Decision:* Maps remain authoritative for `FactionData.controller`. A command
  line or developer override may be added later, but is not part of current
  M15 Part A completion.

### A3 - Flying movement
- *Status:* PLANNED, NOT IMPLEMENTED.
- *Decision:* Player-facing flying rules will be implemented through
  terrain-level movement-cost categories. Units/classes select a movement-cost
  category; flying must not be a unit-level special case that simply ignores
  terrain.

### A4 - Rout elimination
- *Status:* DECIDED; supersedes Decision 8's implicit Rout default.
- *Decision:* Rout is never implicit. A group is eliminated only when an
  authored defeat condition becomes true. Maps that should fail when an allied
  group is wiped must author a Rout defeat explicitly. This preserves valid
  zero-unit states for future reinforcements and objectives that can fail
  without an opposing force.

### A5 - Equipped skill cap
- *Status:* DECIDED.
- *Decision:* The default equipped-skill cap is **5**. A future campaign system
  may override the value through campaign settings; the current direct-boot
  default remains 5.

### A6 - Follow-up threshold
- *Status:* DECIDED.
- *Decision:* A follow-up requires a **5-point Battle Speed advantage**. A
  future campaign system may override the threshold; the current game-wide
  default remains 5.

### A7 - Class weapon-rank caps
- *Status:* DECIDED.
- *Decision:* Every class authors caps for its usable WEXP tracks. **A rank is
  the default maximum** for current classes. The global rank table retains S so
  special classes can opt into an explicit S cap later. WEXP gain stops at the
  active class's authored cap.

### A8 - Documentation directory names
- *Status:* DECIDED.
- *Decision:* Rename `New_Contet_expansion` to `New_Content_Expansion` and
  `Old-deffered` to `Old_Deferred`, updating repository references in the same
  migration.
