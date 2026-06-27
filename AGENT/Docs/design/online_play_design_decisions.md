# Online Play — Design Decisions Catalogue

Status: **RATIFIED 2026-05-17.** All 20 decisions (D1–D20) plus a Steam
distribution precondition were walked through and ratified — see
`AGENT/Docs/archive/consolidation/design_decisions_log_2026-05-17.md` for the recorded outcomes and the
full summary table. The recommendations below were adopted as-is **except**:
- **D6** — sharpened to *(b2) independent animation + a bounded phase barrier*
  (host waits a short capped grace before the next phase) rather than plain (b).
- **D11** — host-pushing content scoped to *data + assets only, never
  scripts/behaviour, and gated on a sandboxed safe-loader* (a pushed `.tres` via
  the default `ResourceLoader` is RCE).
- **D20** — preset/authored armies confirmed as default; bring-your-own-army and
  draft kept explicitly open as **future expansions**.
- **D12** — confirmed blue is **not** host-locked; the host assigns all factions.
- **Steam precondition** — distribution left *undecided*; all netcode is built
  against Godot's high-level multiplayer API so the transport stays swappable.

Date: 2026-05-17
Scope: every design decision required to take the networked-play plan
(`GDD_updates.md` Milestone 15 Part B — Remote Play) from concept to a shippable
online mode. Each entry lists the realistic options with pros/cons and a
recommendation. Companion to `second_player_control_feasibility.md` (which covers
the faction system and hotseat) and the M15 milestone.

Decisions are grouped A–E. The **LAN / online** tag marks when each must be
settled: `LAN` decisions are foundational and needed for the LAN step;
`Online` decisions are only needed for the internet step.

---

## Group A — Architecture & Authority

### D1. Synchronization & authority model  `[LAN]`
- **(a) Deterministic lockstep** — peers exchange only commands; each runs the sim.
  - *Pros:* minimal bandwidth; no state transfer; consistent *if* perfectly deterministic.
  - *Cons:* demands total determinism (RNG, float math, container iteration order); any
    divergence is an unrecoverable desync; hard to debug; future non-deterministic
    content is a standing risk.
- **(b) Host-authoritative client-server** — one player hosts; the host owns the
  truth, validates and applies commands, broadcasts results.
  - *Pros:* no determinism burden; no dedicated-server cost; cheat validation in one
    place; turn-based state is small and changes infrequently, so broadcasting it is cheap.
  - *Cons:* host has a slight latency edge; host disconnect needs handling; a malicious
    host could cheat (acceptable for friendly play).
- **(c) Dedicated-server authoritative** — a neutral server owns the truth.
  - *Pros:* no host advantage; strongest integrity; clean spectating.
  - *Cons:* server infrastructure and running cost; overkill for this audience.

**Recommendation: (b) Host-authoritative.** Turn-based, phase-committed play makes
state transfer trivial, so lockstep's determinism tax buys nothing here, and a
dedicated server is unjustified cost. Revisit (c) only if ranked/competitive online
becomes a goal.

### D2. Command model & granularity  `[LAN]`
- **(a) Whole-phase batch** — the client commits an entire faction phase, sent as
  one message at End Turn.
  - *Pros:* one message per phase; simplest.
  - *Cons:* the opponent watches a frozen screen, then everything resolves at once.
- **(b) Per-action streaming** — each unit's finalised move+action is sent the
  moment it is committed.
  - *Pros:* the opponent watches the phase unfold live; identical command objects to
    (a); much better feel.
  - *Cons:* slightly more messages — still tiny for a tactics game.

**Recommendation: (b) Per-action streaming.** The command objects are the same
either way; flushing them per action costs nothing and watchability is worth it.

### D3. Combat RNG authority  `[LAN]`
- **(a) Host rolls all RNG**, sends outcomes in the broadcast.
  - *Pros:* trivially consistent; no determinism needed anywhere else.
  - *Cons:* none meaningful under host-authority.
- **(b) Shared seeded PRNG** — all peers derive identical rolls.
  - *Pros:* enables command-only relay without shipping outcomes.
  - *Cons:* requires strict, identical RNG call order on every machine.

**Recommendation: (a) Host rolls.** Consistent with D1(b); outcomes ride along in
the authoritative broadcast.

### D4. State reconciliation / desync safety net  `[LAN]`
- **(a) Command-only, no reconciliation** — *Pros:* least traffic. *Cons:* one
  missed or misapplied command silently corrupts the match.
- **(b) Command relay + periodic checksum** — peers hash state each phase; a
  mismatch triggers recovery. *Pros:* catches desync early; cheap. *Cons:* still
  needs a recovery path.
- **(c) Full authoritative snapshot each phase** — host broadcasts complete state at
  every phase boundary. *Pros:* bulletproof; any client error self-corrects within
  one phase; simple. *Cons:* more bandwidth — but full state here (units, tiles, HP,
  inventory) is small.

**Recommendation: (c) for v1.** Stream commands live for presentation (D2), but
treat the per-phase snapshot as the truth. Move toward (b) only if bandwidth ever
becomes a real constraint.

### D5. AI execution location in an online match  `[LAN]`
- (a) Host runs all AI factions; (b) clients each run "their" AI; (c) split.

**Recommendation: (a) Host runs all AI**, broadcasting the resulting commands and
snapshot. One source of truth; consistent with host-authority.

### D6. Animation / presentation pacing  `[LAN]`
- **(a) Logic waits for the slowest client's animations.** *Cons:* one slow machine
  stalls everyone.
- **(b) Each client animates independently from the command stream**; logical state
  is already resolved; the next phase starts on the host's signal.

**Recommendation: (b).** Animation speed is a local presentation concern and cannot
desync resolved state. Add a local-only "skip / fast animation" toggle.

---

## Group B — Connectivity & Infrastructure

### D7. Transport library  `[LAN]` (choice) / `[Online]` (NAT impact)
- **(a) Godot high-level multiplayer over ENet** — built in; RPCs; LAN and online
  (with port forwarding).
  - *Pros:* zero dependencies; same API for LAN and online.
  - *Cons:* no built-in NAT traversal, relay, or matchmaking.
- **(b) Steam Networking Sockets** (via GodotSteam) — if shipping on Steam.
  - *Pros:* free relay, NAT punch-through, lobbies and friend invites out of the box.
  - *Cons:* ties online to Steam; adds the Steam SDK dependency.
- **(c) Custom backend** (Nakama or self-hosted) — full control of matchmaking + relay.
  - *Pros:* platform-independent; scalable.
  - *Cons:* a service to build, host, and maintain.

**Recommendation: build the game on Godot's high-level multiplayer API (a) so the
transport stays swappable; ship online over Steam Networking (b) if Steam is the
distribution target** — it removes all NAT and matchmaking work. Fall back to (c)
only for an off-Steam release.

### D8. NAT traversal  `[Online]`
- (a) Direct connect / manual port forwarding; (b) NAT punch-through; (c) relay server.

**Recommendation: direct + punch-through first, relay as a guaranteed fallback.**
With Steam transport (D7b) this is solved for free; a pure-ENet online release needs
a relay you host.

### D9. Session discovery / matchmaking  `[Online]` (LAN keeps direct IP)
- (a) Direct IP entry; (b) lobby / join-by-code; (c) friends & invites;
  (d) full matchmaking (quickplay / ranked).

**Recommendation: v1 = lobby codes + friend invites (b + c)** — Steam lobbies give
both. Keep direct IP entry (a) as the LAN-stage feature. Full matchmaking (d) is
post-launch and only worthwhile with a player base.

### D10. Version / protocol compatibility  `[Online]`
- (a) Strict exact-version match; (b) compatibility ranges; (c) no check.

**Recommendation: (a) strict match on a protocol-version number**, with a clear
"version mismatch" message. Loosen to (b) only once the netcode has stabilised.

### D11. Content parity (maps / data / mods)  `[Online]`
- (a) Ship-content-only + content-hash check; (b) host pushes content to clients;
  (c) trust.

**Recommendation: (a) hash-check content and reject a mismatch.** Host-pushes-content
(b) is a later feature tied to custom maps / mod support.

---

## Group C — Session & Match Lifecycle

### D12. Faction-to-peer assignment  `[LAN]`
- (a) Host-assigned slots in the lobby; (b) players self-pick; (c) mid-match
  reassignment allowed.

**Recommendation: (a) the host assigns** each of the four factions to a connected
peer or to AI in the lobby; allow one peer to own multiple factions; no mid-match
reassignment except via the disconnect path (D14). Blue need not be the host.

### D13. Lobby / match configuration ownership  `[LAN]`
- (a) Host configures (map, rules — permadeath / leveling method from `GameState`,
  faction assignment); others ready-up. (b) Negotiated / voted.

**Recommendation: (a) host configures, clients ready-up.** Standard and simple.

### D14. Disconnect / reconnection policy  `[LAN]` (basic) / `[Online]` (full)
- (a) Immediate forfeit on drop — *Cons:* brutal; a brief blip ends the match.
- (b) Pause + reconnect window, then a fallback.
- (c) Instant, permanent AI takeover.
- (d) Host migration.

Sub-decisions: reconnect-window length; fallback = AI substitution vs. forfeit vs.
suspend-to-save; host-drop handling.

**Recommendation: (b).** Pause, hold a host-configurable reconnect window
(~60–120 s); on expiry, offer AI substitution (resumable if the player returns) or a
mutual end-with-save. For a **host** drop in v1, end the match to a suspend save
rather than building host migration — migration (d) is a large feature; defer it.
This leans on the mid-battle suspend save already in the Phase 3 backlog.

### D15. Turn timer / pacing  `[Online]`
- (a) Untimed; (b) optional per-phase timer; (c) chess-clock.

**Recommendation: (b) optional per-phase timer, default off or generous.** A timeout
feeds the AFK branch of D14. Chess-clock (c) is a ranked-mode nicety for later.

### D16. In-match save / cross-session resume  `[Online]`
- (a) No resume — a match lives only within its session; (b) suspend & resume across
  sessions.

**Recommendation: (a) for v1** — in-session reconnect only (D14). Cross-session
resume (b) is valuable but rides on the full mid-battle suspend-save feature landing
first.

### D17. Spectators  `[Online]`
- (a) None; (b) live spectators; (c) replays.

**Recommendation: (a) none for v1.** The host-authority + snapshot-broadcast model
(D1b / D4c) makes adding spectators cheap later — a deliberate easy extension, noted
here so nothing precludes it.

---

## Group D — Trust & Information

### D18. Cheat prevention / trust model  `[LAN]`
- (a) Full trust (friendly co-op).
- (b) Host validates every command — unit ownership, legal move, legal target,
  range, action legality — before applying.
- (c) Server-authoritative with adversarial anti-cheat.

**Recommendation: (b) host validates every command.** Catches both bugs and casual
cheating — the right level for a friendly-competitive turn-based game. (c) is only
justified by ranked online with real stakes.

### D19. Fog of war / hidden information  `[Online]`
Fog of war is in the Phase 3 backlog. If online must support fog, the host must send
each client only what that client can see — otherwise a client holds (and could
read) hidden enemy state.
- (a) v1 online = full information, no fog.
- (b) Online supports fog from the start (host filters per-client state).

**Recommendation: (a) v1 online ships without fog.** Per-client state filtering (b)
is a real cost; tackle it only when fog itself ships, and treat "online + fog" as an
explicit combined feature. Flag the dependency now so D4's snapshot design leaves
room for per-client filtering later.

---

## Group E — Game-Design-Facing

### D20. Army source for the non-blue factions  `[LAN]`
In the campaign, blue's roster persists between maps. Online PvP needs the other
armies' units to come from somewhere.
- (a) Preset map armies — each map defines all four armies.
- (b) Bring-your-own-army — roster building with a points / balance system.
- (c) Draft.

**Recommendation: (a) preset map armies for v1.** Bring-your-own (b) is a large
separate feature — an army builder, points balancing, validation — and effectively a
different game mode; defer it. Preset armies also keep maps balanced and authored.

> **Update 2026-06-27d:** (b) is now **scoped as a distinct PvP campaign mode** in
> `registers/pvp_mode_open_questions_2026-06-27.md` `[PVP-1..8]` — a PvP campaign with a hub + map
> selector + a **freeform buy phase reusing the prep panels** (recruit/shop/training-hall/bonus-EXP)
> funded by an author-defined resource budget. **(a) preset armies stays the regular campaign's path;**
> (b) is the opt-in PvP mode. The buy-phase "army builder" = the existing panels + a budget, **not** a
> bespoke builder.

---

## Summary — sequencing

**Settle before the LAN step (M15 Part B, LAN):**
D1, D2, D3, D4, D5, D6, D7 (transport choice), D12, D13, D18, D20 — and the basic
form of D14 (in-session reconnect).

**Add for the online step:**
D8, D9, D10, D11, D15, D16, D17, D19 — and the full form of D14.

**The one decision that shapes everything:** D1. Choosing host-authoritative (b)
makes D3, D4, D5, D18 fall out naturally and removes the determinism burden lockstep
would impose on combat and AI. Decide D1 first.

**The cheapest big risk-reducer:** design Milestone 15 Part A's hotseat controller
to emit a **stream of committed action commands per phase** (D2's command objects),
not just imperative `MapCursor` calls. That single choice pre-builds the command
layer the LAN step needs — see `GDD_updates.md` M15 Part B.
