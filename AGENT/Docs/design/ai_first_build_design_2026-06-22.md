---
Type: design
Status: Target design — build-ready
Last verified: 2026-06-23
---

# AI First-Build Design — Composition Engine (MVP build spec)

**Started:** 2026-06-22
**Status:** Design — build-ready spec for the first AI build. Synthesizes the RESOLVED decisions
`[AIP-1..10]` + `[AIP-A11/A12]` into one implementable design. Rationale/history lives in the
decisions register; the long-term north star lives in the vision doc. **Not** a decisions register.
**Source / companions:** `ai_profiles_open_questions_2026-06-21.md` (decisions `[AIP-*]`),
`ai_system_design_vision_2026-06-22.md` (vision), `map_events_triggers_open_questions_2026-06-21.md`
(`set_ai` action), `GDD_08_Enemy_AI.md` (code-facing AI contract — update at build per DoD#1).
**Gated by:** Package A determinism + §2 save slice for the `ai_awake` field. Build Package A first.

---

## 1. Scope

**In the first build:** the composition engine + these MVP behaviors —
- **Dispositions:** `pursue_unit` (basic), `hold_tile` (passive/guard_tile unified), sleep+latch
  (`territorial`), leashed return-home (`tethered`), `flee` (±`goal_tile`), `seek_tile`.
- **Activation:** `always`, `proximity` (latch / non-latch), `event/flag` (via `set_ai`).
- **Engagement:** `target_policy` = `nearest` | `weakest`.
- **Cross-cutting:** `group_id` (shared aggro + `set_ai` target), `is_boss` compose, reinforcement
  AI (`act_on_spawn`), allied/green-NPC AI (same system), the MET **`set_ai`** action.
- **9 starter presets** (§4) as the authoring surface.

**Explicitly deferred** (do NOT build now; seams must stay open — §10): difficulty bands, the
action-preview, disposition telegraph visuals, the combat-AI workstream (weapon-select / trade-eval
/ item-use / value targeting), fast-follow profiles (`retreat_when_low`, `kite`, `hunt`, true
route-patrol), gated profiles (`fog_scout`/`chest_looter`/`siege_operator`/`buffer`/`thief_steal`/
`dancer`), the `unit_hp_below` trigger, AI pair-up/rescue.

## 2. Architecture — composition engine + planner

A unit's AI is a composition of three axes (vision §0), resolved into an **`AISpec`** and executed
by a **planner**. This replaces the current `match enemy.data.ai_profile` in `EnemyAI._act()`.

- **`resolve_ai_spec(placement, group, difficulty) -> AISpec`** — layers, later overriding earlier:
  base **preset** → per-placement axis overrides → group inheritance → difficulty overlay *(the
  difficulty layer is a no-op stub in the first build; the call signature reserves it)*.
- **`AISpec = { activation, disposition, engagement }`** (+ resolved params: `home_tile`,
  `aggro_radius`, `leash_radius`, `goal_tile`, `target_policy`, `group_id`).
- **`plan_action(unit, board) -> PlannedAction`** — a **pure function of state** (determinism +
  reusable later by the action-preview dry-run). `EnemyAI` then executes the `PlannedAction`.

**Four invariants the build MUST honor** (vision §4 — they keep every deferred item additive):
1. Profiles resolve to an `AISpec`; **no behavior hardcoded in a `match`**.
2. Disposition target is **unit-or-tile** from day one (so `seek_tile`/`flee goal_tile` are data).
3. Activation **reads an optional event/flag** from day one (so `set_ai`/event-aggro is data).
4. Engagement is a **function seam**, even though v1 engagement is just "attack best target."

Keep AI hostile lookup funnelled through the existing `_living_hostiles_for_faction` seam (already
relational) so allied-NPC targeting ([AIP-10]) and a future `ai_respects_fog` rule wrap one function.

## 3. Data model

**New optional `enemy_placements` keys** (and identical on MET `spawn` placements — [AIP-9]):
`ai_profile`/preset (string), `group_id` (string), `home_tile` (Vector2i, default = spawn),
`aggro_radius` (int), `leash_radius` (int), `goal_tile` (Vector2i), `target_policy` (string),
`act_on_spawn` (bool, default false; reinforcements only).

**Validated sets** (boot validator in `DataManager` + a `check_docs` guard mirroring them — DoD#2):
- `_VALID_AI_PROFILES` += `territorial`, `guard_tile`, `tethered`, `flee`, `seek_tile`.
- `_VALID_TARGET_POLICIES = ["nearest", "weakest"]`.

**`GameConstants`** ([AIP-4]): `DEFAULT_AGGRO_RADIUS`, `DEFAULT_LEASH_RADIUS` (aggro ≈ movement +
weapon range). Authors usually set nothing; override per placement for special cases.

**Save field** ([AIP-5]): `ai_awake` per unit (territorial/tethered only) — keyed **per `group_id`**
for grouped units ([AIP-A12]), per-unit for ungrouped. Reserve in §2 schema; add to
`test_snapshot_coverage` STATIC_FIELDS at build.

## 4. Starter preset library ([AIP-7], 9 presets)

| Preset | Activation | Disposition | Engagement | Notes |
| --- | --- | --- | --- | --- |
| `grunt` | always | pursue_unit | nearest | = `basic` |
| `guard` | always | hold_tile (`home_tile`=spawn unless authored) | nearest | unifies passive/guard_tile; +`is_boss`→throne |
| `sleeper` | proximity (latch) | pursue when awake | nearest | = `territorial` |
| `tethered` | proximity (no latch) | pursue / return-home | nearest | leashed |
| `coward` | always | flee (from threat) | — | |
| `runner` | always | flee → `goal_tile` | — | escape toward exit |
| `raider` | always | seek_tile (`goal_tile`) | nearest | Defend-chapter attacker |
| `hunter` | always | pursue_unit | weakest | focus-fire |
| `healer` | always | reach injured ally | heal | existing |

**Precedence** (later wins): base preset → placement override → group → difficulty. An override
replaces **only its axis**; `target_policy` layers onto any *targeting* disposition; **`flee`
ignores `target_policy`**.

## 5. Behaviors (per-activation procedure)

- **`pursue_unit`** — existing `basic`: nearest hostile → best attack tile (or close) → attack →
  staff-heal fallback. `target_policy` redirects "nearest" → policy choice, and threads into the
  move-tile pick.
- **`hold_tile`** — stay on `home_tile`; attack any target reachable from it; never step off.
- **sleep+latch (`territorial`)** — while asleep behave as `hold_tile`; **wake** when a player
  enters `aggro_radius` of `home_tile` OR the unit takes damage (§7 refinement); on wake **latch**
  (`ai_awake`) and delegate to `pursue_unit`. `aggro_radius` ≥ attack range.
- **leashed (`tethered`)** — wake like territorial but **non-latching**: when all players leave
  `leash_radius`, return toward `home_tile` and re-sleep (hysteresis: wake on small `aggro_radius`,
  sleep on larger `leash_radius`).
- **`flee`** — within move range, maximize distance from nearest threat; never attack. With
  `goal_tile`, instead move *toward* it while avoiding threats (`runner`); cornered → least-bad tile.
- **`seek_tile`** — advance toward `goal_tile`, attacking the nearest target en route (`raider`);
  reuses the unit-or-tile disposition target (invariant 2). Defend lose-condition wiring is the
  objective system's job, not the planner's.

## 6. Activation, `set_ai`, and grouping

- **Event/flag activation** ([AIP-8]) — activation may be gated on a map-flag/event, not just
  proximity. The MET **`set_ai`** action ([AIP-A11]) overrides a target's resolved `AISpec`:
  - target = a **unit id OR a `group_id`**; payload = a **partial `AISpec` patch** (any subset of
    preset/axes). The planner reads the new spec on the unit's next activation.
  - "Wake/charge a group on turn N" = `set_ai{ group_id, activation: active }`; role-flip =
    `set_ai{ group_id, preset: "coward" }`. Driven by existing MET triggers
    (`turn_reached`/`unit_died`/`flag`).
- **Grouping** ([AIP-A12]) — any member entering `aggro_radius` or taking damage wakes the whole
  `group_id`; wake latch is per-group. The point of groups: a squad activates together.

## 7. Reinforcements · allied NPCs · bosses

- **Reinforcements** ([AIP-9]) — MET-`spawn`ed units carry the same AI keys; `act_on_spawn: bool`
  (default false) → true = ambush spawn (acts the turn it arrives).
- **Allied / green NPCs** ([AIP-10]) — same composition system, no special-casing; targeting via
  faction relations. A green ally can be any preset.
- **Bosses** ([AIP-1]) — `is_boss` (existing flag) composes onto a disposition (sitting boss =
  `guard` + `is_boss` + throne; hunting boss = `grunt` + `is_boss`). Not a profile.

## 8. Determinism

Per GDD_08 §Determinism (already stated): AI decisions are a pure function of snapshotted state +
the deterministic event stream; tie-breaks use stable ordering (path cost, then a deterministic
key). The planner's `plan_action` purity (§2) is what makes both determinism and the later
action-preview dry-run possible. Any future ML eval (vision §6) must feed a ranking into these
deterministic tie-breaks, never introduce nondeterministic float ordering.

## 9. Build slice (ordered) + tests

1. **Spec resolver + validator + data keys** (§3) — `resolve_ai_spec`, the new placement keys,
   validated sets, `GameConstants` defaults. DoD#2 check_docs guard for the value-sets.
2. **Planner** — `plan_action` pure seam replacing the `match`; port `basic`/`passive`/`healer`
   onto it (no behavior change) to prove the seam.
3. **Dispositions** — `hold_tile` (guard), sleep+latch (territorial, `ai_awake`), leashed
   (tethered), `flee` (±goal_tile), `seek_tile`.
4. **`target_policy`** — thread `weakest` through target + move-tile choice.
5. **Grouping + activation + `set_ai`** — group-keyed aggro/latch; event/flag activation; the MET
   `set_ai` action (unit/group target, partial patch).
6. **Reinforcement keys (`act_on_spawn`) + allied-NPC verification + `is_boss` compose.**
- **Tests** (`test_enemy_ai` + friends): guard never leaves home; territorial latches and stays
  awake after retreat; tethered returns/re-sleeps; flee increases min-distance and never attacks;
  runner moves toward `goal_tile`; raider advances to `goal_tile` engaging en route; `weakest`
  picks the killable target; a `set_ai{group_id}` event wakes/role-swaps the whole group; an
  `act_on_spawn` reinforcement acts the turn it spawns; allied-NPC targets by relation;
  `test_data_manager` rejects unknown profile/policy; `test_snapshot_coverage` covers `ai_awake`.

## 10. Deferred — seams that keep it additive

*Scope below reflects the Group B resolutions (`[AIP-11..16]`, 2026-06-22e). All remain deferred
seams — none is built in the first slice — but their final shape is now fixed, so the seam stubs
can be written to the right contract.*

- **Difficulty bands** → the `difficulty` layer of `resolve_ai_spec` (no-op stub now). **[AIP-11]:
  numbers only** — when implemented this layer may scale **stats** and add **roster/reinforcements**
  but must **not** mutate the resolved `AISpec` axes (activation/disposition/engagement). Keep the
  band overlay applying to the roster/stat side, *not* the spec resolver's axis output.
- **Action-preview** → a dry-run of `plan_action` (pure already). **[AIP-12]:** enabled by any of a
  per-chapter author flag, a per-band marker, or a player accessibility toggle (accessibility wins);
  non-binding ("may change") UX.
- **Disposition telegraph** → **[AIP-13]: character-sheet item + More Info page** (not an on-map
  glyph in v1). The runtime must expose the resolved disposition as a **queryable property** of the
  unit so the `I`-sheet can read it; the on-map intent telegraph stays the danger-zone / threat-range
  overlays.
- **Combat-AI workstream** (gap 3) → the Engagement function seam (invariant 4). **[AIP-14]:** its
  own later milestone; a smarter engagement tier is gated **per-chapter / global setting, NOT a
  difficulty band** (forced by [AIP-11]). **Now design-walked** as the `[VAL]` register
  (`registers/ai_valuation_engagement_open_questions_2026-06-27.md`, 2026-06-27b): whole-action scoring
  over `preview_combat`, F16-tree scores, configurable `search_depth`, author-selectable activation order.
  This pure-planner seam (§2) is its stated prerequisite (`[VAL-10]`).
- **Fast-follow profiles / `unit_hp_below` / true route-patrol / AI pair-up-rescue** → new presets
  or one new axis value each; never a rewrite. **[AIP-15]** `unit_hp_below` = a later MET trigger;
  **[AIP-16]** enemy/allied pair-up/rescue is player-only in v1.
- **Gated profiles** → land as new presets when FOW/DCH/STW/M8-M9 ship.
- **ML eval (Option A)** → swaps the Engagement evaluator; feeds deterministic tie-breaks (vision §6);
  gated **per-chapter/global, not a band** ([AIP-11]/[AIP-14]).
