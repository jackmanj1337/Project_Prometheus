---
Role: dated
---

# Character-Sheet Stat Breakdown — Design & Plan (2026-06-14)

**Status:** Implemented (2026-06-14) — Stage A + the live combat-only sources
(pair-up, stat skills) shipped; aura stat-contributions remain deferred to M9
(auras are stubs that target hit/dodge/crit, not base stats). The behaviour
contract now lives in GDD_07 §Unit Details Screen; this doc is retained as the
design record. Code: `StatBreakdown` (decomposition+caps), `StatContributions`
(collector), `UnitDetailsScreen` (render+green). Tests: `test_stat_breakdown`,
`test_stat_contributions` (drift guard), `test_class_stat_caps`,
`test_unit_details_screen`, `test_pair_up_bonus_e2e`.

## 1. Goal

Make the `I` inspect screen (`UnitDetailsScreen`) a comprehensive, trustworthy
readout of *why* a unit's stats are what they are. For each stat, show:

- **Personal base** — the unit's own value before class contribution.
- **Class base** — the contribution from the current class.
- **Class cap** — the class's ceiling for that stat (loud `NO_CAP_DEFINED`
  placeholder when a class fails to author one; a distinct "—" for the
  intentionally-uncapped MOV / CON / LoS).
- **Active bonuses** — every currently-applied bonus with its **amount and
  source** (pair-up, auras, personal skills, equipped/expended items, tonics,
  rally, terrain, …).
- **Green highlight** — any stat whose effective value is raised above its
  base+class value by an active bonus renders in green.

### Why now
The v0.1.5.0 #8.5 report (*"no pairup line showed in lead unit character sheet"*)
is most likely literal and correct: the pair-up "Paired +N" line lives only on the
**HUD corner panel**, never on the `I` character sheet. The sheet shows tonics (they
persist in `active_modifiers`) but not pair-up (combat-only). This feature closes
that asymmetry and generalises it to all bonus sources.

## 2. Current state (as built)

Two surfaces show stats; they disagree:

| Surface | File | Shows pair-up? | Shows tonics? | Per-stat breakdown? |
|---|---|---|---|---|
| HUD corner panel | `HUD.gd` (`_pairup_bonus_text`) | Yes (on-demand resolver query) | No | No |
| `I` inspect sheet | `UnitDetailsScreen.gd` + `StatBreakdown.gd` | **No** | Yes | Yes (Base/Effective/Growth/Fixed/Modifiers) |

`UnitDetailsScreen._format_mods_block()` calls `StatBreakdown.build(unit, stat)`,
which reads **only `data.active_modifiers`** plus `get_effective_stat`. `StatBreakdown`
already has friendly source labels including `"pair_up" → "Pair Up"` and a
`"combat" → "this combat"` duration string — the plumbing exists, nothing feeds it
outside a fight.

### The persistent-vs-combat-only split (the crux)
Stat-affecting modifiers come from two classes of source:

- **Persistent** — written to `data.active_modifiers` with a real duration and so
  visible outside combat:
  - Items / tonics — `ItemHandler.gd:51` → `add_modifier(stat, Δ, "item:<id>", dur, dur_type)`.
- **Combat-only** — applied at combat start with `duration_type="combat"` and cleared
  after the fight by `Unit.clear_combat_modifiers()`; **absent outside combat**:
  - Pair-up — `CombatResolver._apply_pair_up_bonuses` → source `pair_up:<id>:<stat>`.
  - Aura skills — `SkillHandler` `on_combat_apply_modifiers` (fired per nearby bearer).
  - Personal stat skills — `SkillHandler._apply_stat_bonus` → source `skill:<id>`.
  - Resolve — `SkillHandler` → sources `resolve_*`.

To show the combat-only sources on the sheet, we must **compute** them, not read
them. The lesson from #8.5 is explicit: *do not let two code paths diverge.* So the
computation must be a **single shared collector** that combat also uses — never a
re-implementation of the bonus math for the UI.

## 3. Data-model findings

- `ClassData` exposes `base_hp/strength/magic/defense/resistance/skill/speed/luck/
  movement/constitution/line_of_sight` and `stat_caps`.
- **All current class `.tres` define `stat_caps`** for HP + the 7 combat stats
  (verified across `data/classes/*.tres`, e.g. cavalier =
  `{hp:60, str:26, mag:20, def:26, res:26, skl:25, spd:25, lck:30}`). MOV/CON/LoS are
  intentionally uncapped (no keys) per the `ClassData` comment and the GDD cap tables.
  So `NO_CAP_DEFINED` is a **loud data-integrity signal**, not an expected common state.
- **Decomposition:** `ClassData` base stats are "copied to UnitData at unit creation",
  and reclass swaps class base contributions (keeps personal gains). So:
  - `class_base = class_data.base_<stat>`
  - `personal_base = data.<stat> - class_base` (the unit's own accumulated value)
  - `effective = data.<stat> + Σ active bonuses`
  - **Caveat:** authored test units set `data.<stat>` directly and may not satisfy
    `data.<stat> ≥ class_base`, making `personal_base` negative. Handle gracefully
    (clamp display at 0 and/or label the row "Total (authored)" when the invariant
    breaks) rather than showing a negative personal base.

## 4. Proposed design

### 4.1 Shared collector — `StatContributions` (drift-safe, single source of truth)

Add a collector that returns, for one unit in the current board state, every stat
bonus currently in effect, keyed by stat, each entry `{source_id, source_label,
delta}`. Crucially, **`CombatResolver` is refactored to obtain its pair-up / aura /
personal-skill / resolve stat modifiers from this same collector** (or the collector
is extracted *from* the existing combat path), so the sheet and combat can never
report different numbers.

Sources gathered:
1. `data.active_modifiers` (items/tonics/rally/terrain/anything persistent) — read directly.
2. Pair-up — if the unit is a registered lead, `PairUpBonusResolver.bonuses_for(support)`.
3. Auras — scan living units carrying aura skills within range and sum contributions
   (reuse the same per-bearer logic combat uses).
4. Personal stat skills (`_apply_stat_bonus`) and Resolve — evaluate the unit's own
   passive/combat-start stat skills.

Open implementation question (see §7): whether to (a) extract a pure
`collect_stat_contributions(unit, board)` that both combat and the sheet call, or
(b) run combat's existing `_collect_combat_modifiers` in a no-opponent "self-preview"
mode and harvest the resulting `active_modifiers`. (b) maximises fidelity (literally
the combat path) but needs a safe self-context; (a) is cleaner but must be kept in
lockstep with combat by a drift-guard test. **Recommendation: (a) with a drift-guard
test** that asserts the collector's output equals the modifiers combat actually
applies for a representative paired+aura+skill case.

### 4.2 `StatBreakdown.build()` extension

Extend the returned dict with `personal_base`, `class_base`, `cap` (int or the
sentinel for none), `cap_state` (`"capped"` / `"uncapped"` / `"missing"`), and merge
the collector's combat-only contributions into `mods` (tagged with their existing
`"this combat"` duration label). Keep the existing `base`/`effective`/`mods` keys so
current callers (HUD, tests) don't break.

### 4.3 `UnitDetailsScreen` render

Per selected stat, the breakdown block becomes:

```
Strength
  Personal base   6
  Class base     +4   (Cavalier)
  Class cap       26
  ── Effective    13 ──            (green when bonuses raise it)
  Bonuses:
    Pair Up      +3   (this combat)
    Outdoor Fighter +2 (this combat)
    Strength Tonic +4  (3 turns)
```

- **Green rule:** the Effective value renders green when `effective > personal_base +
  class_base` (i.e. at least one active bonus is raising it). Optionally render the
  capped value amber when `effective ≥ cap`.
- **Cap line:** show the integer when present; render a very obvious
  `NO_CAP_DEFINED` when a combat stat has no cap key (data error to fix at source);
  render "—" for MOV/CON/LoS where uncapped is intentional.

## 5. Staging

- **Stage A — persistent + pair-up + caps + green (low risk).** Decomposition rows,
  cap rows, `active_modifiers` bonuses (already present), pair-up via the resolver,
  green highlighting. No `CombatResolver` changes. Resolves #8.5 directly.
- **Stage B — combat-only sources via the shared collector (needs the §4.1 refactor).**
  Auras, personal stat skills, Resolve appear (and turn the stat green) outside combat,
  with the drift-guard test binding the sheet to combat.

Stage A is shippable alone; Stage B is the part that touches combat and warrants the
collector design + drift guard.

## 6. Testing plan

- `test_stat_breakdown.gd` — extend for `personal_base` / `class_base` / `cap` /
  `cap_state` decomposition, incl. the authored-unit negative-personal caveat.
- New collector test — each source contributes correctly; empty when none.
- **Drift-guard test** — for a paired + aura + personal-skill unit, the collector's
  per-stat totals equal the modifiers `CombatResolver` actually applies. This is the
  guard that prevents an #8.5-style divergence.
- `test_unit_details_screen.gd` — the rendered block shows the decomposition, the cap
  (and `NO_CAP_DEFINED` path), bonus rows with source, and the green state.
- E2E (extend `test_pair_up_bonus_e2e.gd`) — the `I` sheet, not just the HUD, shows
  the pair-up contribution for the 8.5 matchup.

## 7. Open questions / decisions for implementation time

1. **Collector architecture:** extract-and-share (a) vs combat-self-preview (b). Plan
   recommends (a) + drift guard.
2. **Aura scope outside combat:** auras are position/range-based; on the sheet we show
   the contribution *as it would apply right now* from the unit's current tile. Confirm
   that's the intended semantics (vs "potential").
3. **Green semantics:** green only on positive net bonus; how to show net-negative
   (debuff) — red? Plan assumes green-for-boost, and a later pass for debuff colour.
4. **`NO_CAP_DEFINED` as a check:** candidate DoD#2 — extend `check_docs.py` or a data
   test to assert every playable class authors `stat_caps` for HP + the 7 combat stats,
   so the placeholder only ever appears on a genuine regression.

## 8. DoD when implemented

- GDD_07 §Unit Details / Character Sheet updated with the breakdown contract + green
  rule + cap semantics; matching status flipped in GDD_10 (DoD#1).
- If the cap invariant check is added, it lands in the same change (DoD#2).
