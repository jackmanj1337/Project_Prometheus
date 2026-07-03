---
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-03
---

# Band 7 Arena Implementation Plan

**Started:** 2026-07-03.

**Track IDs:** `B7-ARENA`.

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 7 rows. Drafted from the RESOLVED register `[BEA-4..9]`
([`bonus_exp_arena_open_questions_2026-06-27.md`](../registers/bonus_exp_arena_open_questions_2026-06-27.md)).
**Pulled into v1** by the owner (2026-07-03d) — the row keeps its `B7-ARENA` id but
is now a v1 builder-palette feature, sibling to the `B6-PREP-PROGRESSION` panels.

## Purpose

Build the **arena** — a `[PHB]` opt-in prep panel where a unit fights a **sandboxed
real `CombatResolver` 1v1**, a win paying gold + EXP + wexp through the existing
paths (no bespoke combat). Each panel declares its **risk** (`lethal` obeys the
campaign `death_mode`; `safe` forfeits only the bet) and its **match structure**
(`single` or an `escalating` continue/cash-out ladder). Opponents come from an
**authored table OR a parametric spec** fed by a **shared parametric unit
generator** — the same generator `[THL-8]` `generated` recruits use (one generator,
two consumers).

Arena is **atomic** — a match resolves fully, then returns to prep; there is **no
mid-match save state** and it reuses the gold ledger, so it adds essentially no new
save surface (`[BEA-8]`).

This is a build plan only. It does not authorize starting before the gates land.

## Scope

1. **Arena PHB panel + match config (`[BEA-4]`, `[BEA-6/7]`).** An `arena` entry in
   a node's `prep_panels` (reuse `[PHB]` wholesale), on-map placeable via the
   `[SAC]` dual-surface. Per-panel: `risk: lethal|safe`, `structure: single|
   escalating`, opponent source, bet/reward config.
2. **Shared parametric unit generator (`[BEA-5]` / `[THL-8]`).** `generate_unit(spec)`
   from an authored param spec (class · level/range · stat ranges · equipment) →
   a real `Unit`. The opponent source is an **authored table** *or* a **parametric
   spec**. This is the same generator `[THL-8]` `generated` recruits consume.
3. **Sandboxed match loop (`[BEA-5]`, `[BEA-8]`).** A real `CombatResolver` 1v1 in a
   sandbox; a win pays gold + EXP + wexp through the existing ledger/`add_exp`/wexp
   paths. Reuses `RngService` for reproducibility (atomic, no mid-match save).
4. **Risk resolution (`[BEA-6]`).** `lethal` routes a loss through the single
   `handle_death` path gated by `death_mode` (classic = real permadeath risk;
   casual/phoenix = no permanent loss); `safe` ends the match / forfeits the bet
   with no death. Matching UI risk warning.
5. **Match structure (`[BEA-7]`).** Build both loops; the panel declares which.
   `single` = one authored match + reward; `escalating` = a continue/cash-out
   ladder (each win raises stakes; the player banks or risks the pot).

## Non-Goals

- **No bespoke combat** — arena is the existing `CombatResolver`; if it needs a
  guard for the sandbox context, that is a wrapper, not a second combat path.
- **No mid-match save / suspend** (`[BEA-8]`) — a match is atomic; resolve fully
  then return to prep. The escalating pot lives in the panel session only.
- **No new economy state** — betting/payouts reuse the gold ledger (`[SHP]`/`[CNV]`);
  the `[THL-4]` multi-resource wallet is available if a panel bets a non-gold
  resource, but gold is the default.
- **No recruit-purchase here** — the `[THL-8]` roster-add service lives in the
  `B6-PREP-PROGRESSION` plan (it *reuses* this plan's generator).
- **No AI recruitment/economy valuation** — that is the `B7-AI-RECRUITMENT` track.

## Source Docs

- [`bonus_exp_arena_open_questions_2026-06-27.md`](../registers/bonus_exp_arena_open_questions_2026-06-27.md)
  (`[BEA-4..7]` RESOLVED — PHB panel, sandboxed `CombatResolver` + authored/parametric
  opponents, lethal/safe risk, single/escalating structure; `[BEA-8]` atomicity/
  determinism; `[BEA-9]` reuse map + the shared-generator note).
- [`training_halls_open_questions_2026-06-27.md`](../registers/training_halls_open_questions_2026-06-27.md)
  (`[THL-8]` — the other consumer of the shared parametric unit generator).
- `[PHB]` container register · `[DTH]`/`death_mode` (`[DIF-1]`) · `[SHP]`/`[CNV]`
  gold ledger · `[SAC]` on-map dual-surface.

## Decisions Not To Reopen

- `[BEA-4]`: an `arena` `[PHB]` opt-in prep panel; no new container.
- `[BEA-5]`: real `CombatResolver` 1v1; opponents = authored table **or** parametric
  spec via the shared generator; win pays gold + EXP + wexp through existing paths.
- `[BEA-6]`: per-panel `lethal|safe`; `lethal` still obeys `death_mode` (no special
  arena death rule); `safe` never kills.
- `[BEA-7]`: build both `single` and `escalating`; the panel declares which.
- `[BEA-8]`: atomic match, no mid-match save; `RngService` determinism; gold ledger
  for bets.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates:

- **`B3-PHB`** — the prep-panel container. Hard gate.
- **`B2-DEATH-LIFECYCLE`** — the single `handle_death` path + `death_mode` a lethal
  loss routes through. Hard gate for the `lethal` arm.
- **`B2-RESOURCE-LEDGER`** — the gold ledger for bets/payouts.
- **`CombatResolver` exists today** (`scripts/core/CombatResolver.gd`), as do
  `Unit.add_exp` (l.610) and the wexp path — the match loop reuses live combat.
  Only the PHB container, death-mode, and ledger are unbuilt gates.
- The parametric generator (slice 2) is buildable against the live `UnitData`/`Unit`
  model once its author-param spec is defined; it does not need PHB.

## Existing Code Touchpoints

Verified 2026-07-03 against the live tree:

- **`scripts/core/CombatResolver.gd`** — the 1v1 pipeline the match reuses in a
  sandbox (no bespoke combat).
- **`Unit.add_exp` (l.610)** + the weapon-exp path — a win's EXP/wexp payout.
- **`GameState.party_gold` (l.153)** + its snapshot (l.172/479/500) — the bet/payout
  ledger; a payout mirrors the existing `TurnManager.gd:1028` `party_gold +=` write.
- **`UnitData` / `Unit`** — the model the parametric generator populates (class,
  level, stats, equipment) to build an opponent/recruit.
- **No `prep_panels` / PHB / arena / generator in code yet** (grep clean) — PHB is
  unbuilt; drafted against its planned API, same caveat as the Band 5/6 plans.
- Tests to create: new `test_arena.gd` (match resolve, payout, lethal/safe,
  escalating ladder), `test_unit_generator.gd` (spec → unit, ranges honored,
  determinism).

## Slice 1 - Arena PHB Panel + Match Config

**Goal:** the opt-in panel and its per-instance config. **Gated on `B3-PHB`.**

Files to touch:

- an `arena` PHB panel + the panel config model (`risk`, `structure`, opponent
  source, bet/reward)
- `scripts/tests/test_arena.gd` (new)

Implementation steps:

1. Register an `arena` entry in `prep_panels` (reuse `[PHB]`). On-map placeable via
   the `[SAC]` dual-surface (an on-map arena with its own opponent table).
2. Panel config: `risk: lethal|safe`, `structure: single|escalating`, an opponent
   source (table or spec), and bet/reward parameters.

Tests:

- The panel opens from a node's `prep_panels`; its config drives risk/structure.

F1 obligations: none (panel config is authoring data; matches are atomic).

DoD#1 obligations: update `GDD_07` (arena panel) when the match loop lands.

## Slice 2 - Shared Parametric Unit Generator

**Goal:** build a real `Unit` from an authored param spec — shared with `[THL-8]`.

Files to touch:

- a unit-generator service (`scripts/core/UnitGenerator.gd` or similar)
- `scripts/tests/test_unit_generator.gd` (new)

Implementation steps:

1. `generate_unit(spec) -> Unit` where `spec` = class · level/range · stat ranges ·
   equipment. Roll within the ranges (via `RngService` for determinism) and
   populate a real `UnitData`/`Unit`.
2. The arena opponent source accepts an **authored table** (fixed roster) *or* a
   **parametric spec** (`[BEA-5]`). Expose the same generator for `[THL-8]`
   `generated` recruits (one generator, two consumers) — whichever consumer lands
   first owns the build; the other reuses it.

Tests:

- A spec produces a unit whose class/level/stats/equipment fall within the authored
  ranges; a fixed seed yields the same unit (determinism).
- The generator output is a normal `Unit` usable by `CombatResolver` and `recruit()`.

F1 obligations: none — param specs are authoring data, not save; generated units
persist through the normal roster/`UnitData` save when recruited.

DoD#1 obligations: note the shared generator in `GDD_03` (unit sources).

## Slice 3 - Sandboxed Match Loop

**Goal:** a real 1v1 that pays out — atomic and deterministic.

Files to touch:

- the arena match runner (sandbox `CombatResolver` + payout)
- `scripts/tests/test_arena.gd`

Implementation steps:

1. Resolve a real `CombatResolver` 1v1 in a sandbox (the player's unit vs the
   generated/table opponent), using `RngService` for reproducibility.
2. On a win, pay gold + EXP + wexp through the existing ledger / `add_exp` / wexp
   paths. Resolve the match **fully**, then return to prep — atomic, no mid-match
   save (`[BEA-8]`).

Tests:

- A win pays the authored gold + EXP + wexp; a loss pays nothing (pre-risk).
- The match is atomic — no suspend snapshot is written mid-match.
- Same seed → same match outcome (determinism).

F1 obligations: none (atomic; no mid-match state).

DoD#1 obligations: update `GDD_07`/`GDD_02` (arena rewards) + flip `GDD_10`.

## Slice 4 - Risk Resolution (Lethal / Safe)

**Goal:** a loss respects the campaign death mode or forfeits only the bet.
**Gated on `B2-DEATH-LIFECYCLE`.**

Files to touch:

- the arena match runner (loss branch)
- a UI risk warning
- `scripts/tests/test_arena.gd`

Implementation steps:

1. `lethal` → a loss routes through the single `handle_death` path gated by
   `death_mode` (classic = permadeath risk; casual/phoenix = no permanent loss). No
   special arena death rule.
2. `safe` → a loss ends the match / forfeits the bet; the unit never dies.
3. Show the matching risk warning before a `lethal` match.

Tests:

- A `lethal` loss under classic routes through `handle_death`; under casual/phoenix
  the unit survives (death-mode honored, no arena-specific rule).
- A `safe` loss forfeits the bet and never kills.

F1 obligations: none new — death handling rides the existing `[DTH]` path/save.

DoD#1 obligations: update `GDD_07` (risk warning) + `GDD_02` (death-mode arena
composition) + flip `GDD_10`.

## Slice 5 - Escalating Ladder

**Goal:** the continue/cash-out gamble.

Files to touch:

- the arena match runner (ladder loop)
- `scripts/tests/test_arena.gd`

Implementation steps:

1. `escalating` → after each win, offer continue (raise stakes) or cash-out (bank
   the pot). Each continued match escalates the opponent (via the table tier or the
   spec's level/range) and the pot. The pot is panel-session state only (atomic —
   no mid-match save between ladder rungs is required beyond the prep return).

Tests:

- An escalating ladder raises the pot each win; cash-out banks it; a loss forfeits
  the pot (respecting the panel's `risk`).
- A `single` panel resolves one match with no ladder.

F1 obligations: none (the pot is session-local; banked gold rides the ledger).

DoD#1 obligations: update `GDD_07` (escalating arena) + flip `GDD_10`.

## Implementation Commit Order

1. Slice 1 arena PHB panel + config — **trails `B3-PHB`**.
2. Slice 2 shared parametric unit generator (buildable against live `Unit`; shared
   with `[THL-8]`).
3. Slice 3 sandboxed match loop (reuses live `CombatResolver`; gated by the panel).
4. Slice 4 risk resolution — **trails `B2-DEATH-LIFECYCLE`**.
5. Slice 5 escalating ladder.

## Verification Checklist

Same as the Band 2/3/4/5 plans. Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
```
