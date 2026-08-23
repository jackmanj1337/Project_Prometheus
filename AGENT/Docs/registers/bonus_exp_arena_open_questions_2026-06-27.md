---
Role: dated
Type: register
Status: RESOLVED 2026-06-27
Last verified: 2026-06-27
Register: BEA-1..9
Resolved-in: 2026-06-27d
---

# Bonus-EXP (#18) + Arena (#14) — EXP-Economy Prep Panels — Player-Facing Design + Open Questions

**Started:** 2026-06-27 (session 2026-06-27d). **Fourth A5 sub-item** (after `[DTH]`, `[DIF]`,
`[AGT §6]`). The two remaining **EXP-economy** mechanics (the shop/convoy money economy is already firmed,
`[SHP]`/`[CNV]`). Both are **F9 PHB opt-in prep panels** leaning heavily on reuse. Walked
end-shape-first. Branch `docs-reorg-2026-06-23`. Design-capture only. Legend: **[OPEN]** / **[ASKED]** /
**[RESOLVED]**.

---

## Substrate reality (verified this session)
- **Both unbuilt** (no `bonus_exp`/`arena` code). Both are **`[PHB]` option panels** — opt-in per
  progression node via `prep_panels: [...]`, flat list + cosmetic theme, with the `one_shot`/restock
  cadence flag (`[PHB-1..3]`). The container is already designed.
- **Bonus-EXP reuses the level path:** `Unit.add_exp()` → `level_up()` → `LevelUpScreen` already exist;
  Bonus-EXP just feeds `add_exp` with a player-chosen amount. **No new leveling code** — and it inherits
  the same growth roll (incl. the random-growth `randi` determinism caveat filed under the atlas Phase C
  findings).
- **Arena reuses combat:** a sandboxed real `CombatResolver` 1v1 + the EXP/wexp paths + the gold ledger
  (`[SHP]`/`[CNV]`) + the `[DTH]`/`death_mode` death path. The new surface is the panel + opponent source
  + the match loop.
- **Difficulty hook:** `[DIF-6]` already pinned that Bonus-EXP pools + Arena risk wire to `death_mode` +
  the difficulty selector — this register resolves that pin.

---

## Bonus-EXP (#18)

## [BEA-1] Container = a `[PHB]` opt-in prep panel — **RESOLVED**
A `bonus_exp` entry in a node's `prep_panels`. Reuses F9 PHB wholesale; no new container.

## [BEA-2] The pool — banked, earned by authored awards (+ optional difficulty scaling) — **RESOLVED**
A **banked EXP pool** (campaign-wide; a new save field on `GameState`/save). **Earned via authored
awards** — a **`grant_bonus_exp` award** fired by objectives / `[MET]` actions (ties to the
objective/`[TCV]` system — the same grant plumbing as flags/items) — **plus an optional difficulty
multiplier** (`[DIF]`). Authors fully control amounts + pacing. (Not performance/efficiency-derived in
v1; that can ride a later authored metric.)

## [BEA-3] Spending = feed `add_exp`; cost = author-configurable curve, default 1:1 — **RESOLVED**
In the panel the player selects a unit and pours pool EXP, which **feeds `Unit.add_exp()`** → reuses
`level_up()` + `LevelUpScreen` (random or fixed growths per `leveling_method`). **Cost model = a default
**1 pool point = 1 EXP**, with an **optional `CampaignRules`/`[REQ-16]` cost curve** that scales cost by
unit level (3H-style diminishing) — a balance lever, off by default. Pool spend is **capped at the level
cap** (`add_exp` already discards past-cap + surfaces promotion availability). *Note:* prep-time growths
inherit the random-growth determinism caveat (atlas Phase C findings).

---

## Arena (#14)

## [BEA-4] Container = a `[PHB]` opt-in prep panel — **RESOLVED**
An `arena` entry in `prep_panels`. Reuses F9 PHB; betting/payouts reuse the gold ledger (`[SHP]`/`[CNV]`).

## [BEA-5] Combat = sandboxed real `CombatResolver`; opponents = authored table — **RESOLVED (direction)**
An arena match is a **real `CombatResolver` 1v1** in a sandbox; a **win pays gold + EXP + wexp** through
the existing paths (no bespoke combat). **Opponent source = an authored opponent table per arena panel**
(a content-pack list), optionally **level/tier-scaled** via the `[TCV]`/`[DIF]` difficulty variables.
> **Shared parametric unit generator (`[THL-8]`, 2026-06-27d):** the opponent table generalizes to
> "authored table **or** a **parametric spec** (class · level/range · stat ranges · equipment)" — the
> **same on-demand unit generator** that `[THL-8]` `generated` recruits use. One generator, two consumers.

## [BEA-6] Risk = author lethal/safe toggle per arena; lethal still respects `death_mode` — **RESOLVED**
**Owner: each arena panel declares `lethal` vs `safe`.**
- **`lethal`** → a loss routes through the **single `handle_death` path gated by `death_mode`** (`[DTH]`/
  `[DIF-1]`): **classic** = real permadeath risk; **casual/phoenix** = no permanent loss. (So even a
  lethal arena obeys the campaign's death mode — no special arena death rule.) Needs the matching UI
  risk warning.
- **`safe`** → a loss just **ends the match / forfeits the bet**; the unit never dies. Grind without the
  gamble.

## [BEA-7] Match structure = author-choice: single OR escalating — **RESOLVED**
**Build both loops; the panel declares which.** **Single** = one authored match, authored reward.
**Escalating** = a continue/cash-out ladder (each win raises the stakes; the player **banks or risks**
the pot) — the classic arena gamble. Authors pick per arena.

---

## Cross-cutting

## [BEA-8] Determinism & save — **forward to Phase B (F1 lock)**
- **Bonus-EXP pool** = a new persistent save field (campaign-wide bank). Reserve at the F1 lock.
- **Arena is atomic** — resolve a match fully, then return to prep; **no mid-match save state**. Arena
  combat reuses `RngService` for reproducibility (post-M9a determinism, same as all combat).
- Gold for betting/payout reuses the existing **gold ledger** — no new economy state.

## [BEA-9] Composition / reuse map — **RESOLVED**
- **F9 `[PHB]`** (both = opt-in prep panels) · **F3 `[PXP]`/`Unit.add_exp`** (EXP) · the **prep hub**.
- Bonus-EXP awards ride the **objective/`[TCV]` grant system** (`grant_bonus_exp`); difficulty scaling
  rides **`[DIF]`/`[TCV]`**.
- Arena risk rides **`[DTH]`/`death_mode`** (`[DIF-1]`); arena combat rides **`CombatResolver`** + the
  **gold ledger** (`[SHP]`/`[CNV]`).
- **Sibling not walked here:** Training Halls (#19) is the other prep-panel resource sink (scope map);
  out of this register's scope — same `[PHB]` container if/when taken.
- **Dual-surface (owner 2026-06-27d):** both panels are also **placeable on-map** by map creators as
  `[VIL-2]` instances with per-instance variations (an on-map arena with its own opponent table; a
  bonus-EXP shrine) — the `[PHB]` dual-surface note; the shared panel↔trigger contract firms in the A5
  `shop`/`activate` walk.

---

## Cross-refs
- **`[DIF-6]`** (Bonus-EXP/Arena difficulty + death-mode composition) → resolved here.
- **`[PHB]`** container · **`[PXP]`/`add_exp`** EXP · **`[DTH]`/`death_mode`** arena death · **`[SHP]`/
  `[CNV]`** gold · **`[TCV]`/objective system** (`grant_bonus_exp` award) · **`[REQ-16]`** (cost curve).
- Atlas Phase C findings (random-growth determinism) — Bonus-EXP prep-time level-ups inherit it.
