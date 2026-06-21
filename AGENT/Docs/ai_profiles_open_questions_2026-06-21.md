# Additional AI Profiles (§5) — Draft Plan + Open Questions Register

**Started:** 2026-06-21d
**Status:** Planning draft — register OPEN. Extends an existing system; contained.
**Source:** `planning_backlog_2026-06-20.md` §5; session note 2026-06-21c Tier 2 #4.
**Companion:** `GDD_08_Enemy_AI.md`. **Code:** `scripts/core/EnemyAI.gd`.
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)

- **Profile dispatch exists.** `EnemyAI._act()` switches on `enemy.data.ai_profile`:
  `"passive"` and `"healer"` have dedicated handlers; `"basic"` falls through to the
  default move-to-nearest-and-attack logic.
- **Validated vocabulary is closed.** `DataManager._VALID_AI_PROFILES = ["basic",
  "passive", "healer"]` — adding a profile **requires** extending this const (and per DoD#2
  there's already a validation gate that rejects unknown profiles at boot, plus
  `collect_unit_validation_errors` checks `unit.ai_profile`).
- **`UnitData.gd:66` already names the targets:** `# future: "territorial"|"guard_tile"|
  "boss"`. So the taxonomy is half-declared; this register firms it.
- **Reusable building blocks in `EnemyAI`:** `_find_nearest` (Dijkstra cost flood),
  `_choose_move_tile` (best attack tile / else close distance), `_choose_heal_move_tile`,
  `dijkstra_costs`, terrain-bonus tie-breaks. New profiles compose these, not new pathing.
- **No leash/anchor concept exists.** Every active profile uses whole-map distance; there
  is no "stay within N of a home tile" primitive — `territorial`/`guard_tile`/`boss` need one.

## 2. Draft plan (classic FE convention)

Classic FE AI archetypes the four new profiles map to:
- **`territorial`** ("group"/"area" AI): holds position until a player enters an
  **aggro radius**, then behaves like `basic`; returns toward home if players leave. The
  staple "this room's guards wake when you approach."
- **`guard_tile`** ("stationary guard"/"protect"): never voluntarily leaves a designated
  tile (a throne, gate, treasure); attacks anything in range from that tile. Like `passive`
  but pinned to a *specific* tile rather than its spawn, and often the seize/defense anchor.
- **`healer`** — already implemented; listed for completeness (no work).
- **`boss`**: typically `guard_tile` on the throne with **throne terrain bonuses**, may
  have a `taunt`/leash, and often does NOT pursue. FE bosses usually sit; some "boss hunts"
  pursue. The `is_boss` placement flag already exists in `MapData.enemy_placements`.

The unifying new primitive is a **leash/anchor**: `(home_tile, aggro_radius, leash_radius)`.
`territorial` and `guard_tile` are two configurations of it; `boss` = `guard_tile` + throne.

## 3. Open questions register

### [AIP-1] Profile taxonomy — final set + naming  **[OPEN]**
- **A — Ship all four named in `UnitData`:** `territorial`, `guard_tile`, `boss` (+ existing
  `healer`). Matches the already-written comment and the roadmap line.
- **B — Ship `territorial` + `guard_tile` only**; treat `boss` as a *placement flag*
  (`is_boss` already exists) layered on `guard_tile`, not a distinct profile.
- **Rec: B** — `is_boss` already exists on placements and drives boss-defeat objectives;
  a boss is mechanically `guard_tile` + throne bonuses + (optional) leash. Making `boss`
  its own profile duplicates `guard_tile`. Keep the profile set to the two new *behaviors*;
  let `is_boss` compose. (Revisit if bosses need genuinely unique logic.)
- **Resolution:** _[OPEN]_

### [AIP-2] Leash/anchor data: where does `home_tile` + radii live?  **[OPEN]**
`territorial`/`guard_tile` need a home tile + aggro/leash radii per unit.
- **A — On the `MapData.enemy_placements` dict** (new optional keys `home_tile`,
  `aggro_radius`, `leash_radius`). Placement-specific; the same unit can be territorial on
  one map, basic on another. Matches how `ai_profile`/`is_boss`/`faction` already live there.
- **B — On `UnitData`** (new @export fields). Unit-intrinsic; but a unit's *position-based*
  leash is inherently per-map, not intrinsic.
- **C — Default the anchor to the spawn tile** (no new data); only aggro/leash radii are
  authored, home = where it spawned.
- **Rec: A + C default** — leash is fundamentally a placement concern (it's about a *spot on
  this map*), so it belongs with the other placement keys; default `home_tile` to the spawn
  tile when omitted (C) so most authoring is just `aggro_radius`. This also keeps `UnitData`
  (and its snapshot contract) clean.
- **Resolution:** _[OPEN]_

### [AIP-3] Aggro/leash semantics: latch or re-evaluate?  **[OPEN]**
Once a `territorial` unit wakes, does it stay awake?
- **A — Latch on wake** (once a player enters aggro radius, the unit becomes `basic`
  permanently). Simple, predictable, classic FE "the room woke up."
- **B — Re-evaluate each turn** (returns home / re-sleeps if all players leave the leash).
  More dynamic, but can produce a unit that oscillates at the leash boundary.
- **Rec: A** — latching matches the FE feel and is far easier to reason about (and to test
  deterministically). Returning-home (B) is a polish behavior that can be added per-profile
  later if a map wants a true patrol. The wake-latch state is per-map runtime → reserve a
  snapshot field ([AIP-5]).
- **Resolution:** _[OPEN]_

### [AIP-4] Data-driven thresholds vs hardcoded  **[OPEN]**
- **A — Author radii per placement** ([AIP-2]); no global constants.
- **B — Global defaults in `GameConstants`** (e.g. `DEFAULT_AGGRO_RADIUS`) with per-placement
  override. Less authoring per unit.
- **Rec: B** — a sensible global default (aggro ≈ unit movement + weapon range) means
  authors usually set nothing; override only the special cases. Matches how the codebase
  already centralizes tunables in `GameConstants`.
- **Resolution:** _[OPEN]_

### [AIP-5] Wake-state persistence (snapshot interaction)  **[OPEN]**
The latched "awake" flag ([AIP-3] → A) is mutable per-map state — Retry/suspend must
restore it or a reloaded map could re-sleep a woken room.
- **A — Add an `ai_awake: bool` to the unit snapshot** (mirrors the `UnitData` snapshot
  contract note); recompute nothing.
- **B — Recompute wake state from positions on load** (a unit is awake if a player is/has
  been in range — but "has been" isn't derivable, so this under-restores).
- **Rec: A** — wake is a latched memory, not derivable from current positions; it must be
  serialized. One bool per unit; reserve it in the §2 schema (this register's only §2 ask).
  Update `test_snapshot_coverage` STATIC_FIELDS accordingly.
- **Resolution:** _[OPEN]_

## 4. Slice sketch (provisional)
1. Leash primitive: `home_tile`/`aggro_radius`/`leash_radius` placement keys + `GameConstants`
   defaults; `_VALID_AI_PROFILES` += `territorial`, `guard_tile` (DoD#2: extend the validator
   + a `check_docs` guard if the profile list is doc-mirrored).
2. `_act_guard_tile` (pinned `passive` on `home_tile`).
3. `_act_territorial` (sleep → wake-latch → `basic`), `ai_awake` snapshot field.
4. `is_boss` → `guard_tile` + throne-bonus compose ([AIP-1] → B).

## 5. Test notes
- Extend `test_enemy_ai`: a `guard_tile` unit never leaves `home_tile`; a `territorial` unit
  stays put until a player enters aggro, then closes; wake latches across a turn.
- `test_data_manager`: unknown profile still rejected; new profiles accepted.
- `test_snapshot_coverage`: `ai_awake` covered.
