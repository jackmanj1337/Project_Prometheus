---
Type: register
Status: RESOLVED 2026-06-27
Last verified: 2026-06-27
Register: PVP-1..8
Resolved-in: 2026-06-27d
---

# PvP Mode (#7) — Bring-Your-Own-Army PvP Campaign — Player-Facing Design + Open Questions

**Started:** 2026-06-27 (session 2026-06-27d). **Seventh A5 sub-item** — the last standalone A5 design
item. **Scopes the deferred `[D20(b)]`** ("bring-your-own-army roster building with a points/balance
system") from the **ratified** online-play decisions (`design/online_play_design_decisions.md`,
2026-05-17) — which explicitly called (b) "effectively a different game mode." This register designs that
mode. Almost entirely **reuse**. Branch `docs-reorg-2026-06-23`. Legend: **[OPEN]** / **[ASKED]** /
**[RESOLVED]**.

---

## Substrate reality
- **Online architecture is ratified** (`online_play_design_decisions.md`): host-authoritative (D1b),
  **social-contract trust, NO adversarial anti-cheat (D18)** — *exactly the owner's stance*. **Hotseat**
  (local pass-and-play) is the M15 controller; `debug_hotseat_override` exists, full hotseat = M15.
- **D20 ratified (a) preset map armies for v1** and **deferred (b) bring-your-own-army** as a separate
  mode — **this register is that (b) mode** (it does not change D20a for the regular campaign).
- The buy-phase pieces mostly exist/are-planned: **recruit `[RCR]`**, **shop `[SHP]`/`[SAC]`**, **bonus-EXP
  `[BEA]`**, the **prep hub `[PHB]`** — funded by a resource budget.

---

## [PVP-1] PvP = a distinct campaign TYPE (hub + map-selector + buy + battle + best-of-N) — **RESOLVED**
A PvP match is authored as a **PvP campaign**: a **main hub node** + a **map selector** (`random` or
`from_list`) → per-faction **buy phase** → **battle** on a predesigned map → (single or **best-of-N** with
**inter-round bonuses**). Reuses the **campaign/node system + F4** — a PvP campaign is a campaign with this
structure, not a new engine.

## [PVP-2] Trust / fairness = ratified D18 social contract; NO anti-cheat — **RESOLVED (owner + ratified)**
**Casual/friendly, protected by social contract** — no adversarial anti-cheat, no determinism/fairness
guarantees, no hidden-info enforcement beyond what's natural. **Matches the ratified D18** ("the right
level for a friendly turn-based game"). Hotseat = trust the pass-and-play; online = host-authoritative
(D1b). This **removes** the lockstep/determinism burden for the mode.

## [PVP-3] Buy phase = freeform buy funded by a faction budget, reusing the prep panels — **RESOLVED**
Each faction spends a **resource budget** to build its army via the **existing prep panels** — **no
bespoke army-builder**:
- **units** → **recruit `[RCR]`** (freeform: buy any unit from the authored available pool — owner);
- **equipment** → **shop `[SHP]`/`[SAC]`**;
- **levels** → **bonus-EXP `[BEA]`** (pool spend → `add_exp`);
- **stats / skills / weapon-XP** → **training-hall #19** (the "spend resources for stat/skill/XP" sink).
**Dependency:** the stats/skills part needs **training-hall #19** — **now DESIGN-RESOLVED `[THL-1..7]`**
(2026-06-27d); the full buy-phase **build still waits on the `[THL]` build**. (Buy-a-skill = `[THL-2]` →
`earned_skills` + the `[LDC]` cap; buy-a-stat = `[THL-3]` permanent stat-gain primitive over `[STM]`.)

## [PVP-4] Resource & inter-round model = fully author-defined — **RESOLVED**
**Owner:** **author sets everything** — starting budgets (symmetric by default, **asymmetric/handicap
open**), and an **arbitrary inter-round bonus formula** (flat, catch-up-for-the-loser, performance-based,
…). Rides the **`[TCV]` tuning variables + `[REQ-16]` formulas** (the tuning subsystem is the natural
home for author-defined budget/bonus values). No fixed balance rule baked in.

## [PVP-5] Match structure = author config (rounds · map-select · aggregation) — **RESOLVED**
A PvP campaign declares: **`rounds`** (`single | best_of_N`), **`map_select`** (`random | from_list`), and
**win aggregation** (a round win = the map's normal objective met `[ObjectiveCondition]`; the match goes to
first-to-⌈N/2⌉). Between rounds: re-run the buy phase (with PVP-4 bonus resources) → next map. Mostly
CampaignRules-level authoring config.

## [PVP-6] Control = reuse the hotseat (M15) + ratified online controller — **RESOLVED (reuse)**
PvP is a **consumer of the faction controller**, not a new control system: **hotseat (M15) local
pass-and-play is the v1 path**; networked PvP rides the **ratified host-authoritative online architecture**.
Both the buy phase and the battle run per controlling faction.
> **Related (`[D21]`, 2026-06-27d):** the *same* per-faction control substrate also lets **regular story
> campaigns** be multiplayer as an author decision — **co-op vs AI** or a **human game-master** driving the
> normally-AI factions. PvP is the *competitive* use; co-op/GM are the *cooperative/authored* uses. One
> control-assignment mechanism, three intents.

## [PVP-7] Death / loss = `death_mode` (no permanent loss across the match) — **RESOLVED**
PvP rides the `[DIF-1]`/`[DTH]` death path with **no permanent roster loss** — rounds are self-contained;
a faction's army is (re)built each buy phase per the author's persistence rule. (The `[DIF]` PvP = "moot,
fresh loadout per match" note generalizes here.)

## [PVP-8] Dependencies, sequencing & save — **forward**
- **Un-defers `[D20(b)]`** as a *planned* mode (D20a preset-armies stays the regular campaign's path).
- **Build deps:** training-hall #19 (PVP-3) · the M15 hotseat controller · (networked) the online build.
- **Save/F1:** a **PvP-campaign save shape** — per-faction budgets, round-win tally, bought rosters — mostly
  rides the **campaign save + `[TCV]` variables**; reserve the PvP-campaign fields at the F1 lock.

---

## Cross-refs
- **`[D18]`/`[D20]`/`[D1]`** (ratified online decisions — trust, army source, authority) · **M15 hotseat**
  · **`[RCR]`** (recruit) · **`[SHP]`/`[SAC]`** (shop) · **`[BEA]`** (bonus-EXP) · **training-hall #19**
  (stat/skill/XP buy — *dependency, undesigned*) · **`[PHB]`** (prep panels) · **`[TCV]`/`[REQ-16]`**
  (author-defined budgets/bonuses) · **`[DIF-1]`/`[DTH]`** (death mode) · **`[LDC]`/`[STM]`** (bought
  skills/stats).
