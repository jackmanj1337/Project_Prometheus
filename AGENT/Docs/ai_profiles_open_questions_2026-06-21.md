# Additional AI Profiles (§5) — Draft Plan + Open Questions Register

**Started:** 2026-06-21d
**Status:** RESOLVED 2026-06-21k — all of `[AIP-1..5]` resolved + a full canonical profile
target list drafted (§2a). MVP grew past the original two profiles. Build-ready (the `ai_awake`
save field rides §2). Extends an existing system; contained.
**Source:** `planning_backlog_2026-06-20.md` §5; session note 2026-06-21c Tier 2 #4.
**Companion:** `GDD_08_Enemy_AI.md`. **Code:** `scripts/core/EnemyAI.gd`.
**MVP profile set (owner-chosen):** `territorial` + `guard_tile` + `patrol` + `flee`, plus a
`target_policy` placement modifier (`nearest` default + `weakest`), plus `is_boss` compose.
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

**Cross-register convergence (audit 2026-06-21d):** three other registers defer an
enemy-behavior follow-up to *this* system rather than inventing their own mini-AI — they
should all land as new profiles here, not as parallel plans:
- **Fog scout** ([FOW-3] → C) — a profile that respects fog (vs the default cheat).
- **Chest looter** ([DCH-4] → B) — path-to-chest → open → flee (the classic thief race).
- **Siege operator** ([STW-6] → B) — mount + fire an emplacement on the enemy phase.
Each reuses the leash/target machinery below; folding them in here keeps one AI taxonomy.

## 2a. Full profile target list (canonical roadmap) *(drafted 2026-06-21k)*

The owner asked to enumerate the **entire** profile universe and bucket it, so this is the
single source of truth for what AI behaviors exist and when they land. Key framing insight:
most "profiles" people list collapse onto **two orthogonal axes plus one modifier**, so the
taxonomy is small and composable rather than a long flat enum.

**Axis 1 — engagement disposition (when/whether it moves to fight):**

| Profile | Behavior | Bucket | Data / gate |
| --- | --- | --- | --- |
| `basic` | pursue & attack nearest; staff-heal fallback | **built** | — |
| `passive` | hold position; attack only what's already in range | **built** | — |
| `guard_tile` | pinned to a designated tile (throne/gate); attack in range, never leaves | **MVP** | `home_tile` (default spawn) |
| `territorial` | sleep at home until a player enters `aggro_radius` → **latch** awake → `basic` | **MVP** | `home_tile`/`aggro_radius`/`leash_radius`; `ai_awake` save |
| `patrol` | like `territorial` but **non-latching** — returns home / re-sleeps when players leave `leash_radius` | **MVP** | same leash keys; no latch |
| `flee` | every turn move to maximize distance from nearest threat; never engage (villagers, runners, cowards) | **MVP** | none (inverse pursuit) |
| `retreat_when_low` | `basic` until below an HP threshold, then `flee` | fast-follow (ungated) | `retreat_hp_pct` key |
| `kite` | prefer attacking from a tile where the target can't counter (mages/archers) | fast-follow (ungated) | counter-prediction in tile scoring |

**Axis 2 — special role / action (the unusual thing it does):**

| Profile | Behavior | Bucket | Gate |
| --- | --- | --- | --- |
| `healer` | chase injured ally, heal most-injured in range | **built** | — |
| `buffer` | rally / restore / boost staves | gated | M9 staff content |
| `thief_steal` | steal an item from a player, then flee | gated | steal mechanic |
| `fog_scout` | respect fog / reveal (vs the default cheat) | gated | **FOW** ([FOW-3] → C) |
| `chest_looter` | race to chest → open → flee (the thief race) | gated | **DCH** ([DCH-4] → B) |
| `siege_operator` | mount + fire a ballista/emplacement on the enemy phase | gated | **STW** ([STW-6] → B) |
| `dancer` | re-activate an ally (niche as an enemy) | gated | dance mechanic |

**Modifier — `target_policy` (orthogonal; a placement key, NOT a profile — applies on top of any
disposition):**

| Value | Behavior | Bucket |
| --- | --- | --- |
| `nearest` (default) | current behavior — closest reachable target | **MVP (default)** |
| `weakest` | focus-fire: prefer the target it can kill / most damage / lowest effective def | **MVP** |
| `hunt:<unit_id>` | assassin / escort-hunter — fixate on one player unit | fast-follow (ungated) |

**Boss is not on any axis** — `is_boss` (existing placement flag) **composes** onto a
disposition: sitting boss = `guard_tile` + `is_boss` + throne bonus; hunting boss = `basic` +
`is_boss`. See [AIP-1].

**Bucket summary:**
- **MVP (this register builds):** `territorial`, `guard_tile`, `patrol`, `flee` + the
  `target_policy` modifier (`nearest`+`weakest`) + `is_boss` compose.
- **Fast-follow (ungated, build anytime):** `retreat_when_low`, `kite`, `hunt` target policy.
- **Gated (land with parent feature):** `fog_scout` (FOW) · `chest_looter` (DCH) ·
  `siege_operator` (STW) · `buffer` (M9 staves) · `thief_steal` (steal mech) · `dancer`.

## 3. Open questions register

### [AIP-1] Profile taxonomy — final set + naming  **[RESOLVED → two axes + modifier; boss = flag]**
- **A — Ship all four named in `UnitData`:** `territorial`, `guard_tile`, `boss` (+ existing
  `healer`). Matches the already-written comment and the roadmap line.
- **B — Ship `territorial` + `guard_tile` only**; treat `boss` as a *placement flag*
  (`is_boss` already exists) layered on `guard_tile`, not a distinct profile.
- **Rec: B** — `is_boss` already exists on placements and drives boss-defeat objectives;
  a boss is mechanically `guard_tile` + throne bonuses + (optional) leash. Making `boss`
  its own profile duplicates `guard_tile`. Keep the profile set to the two new *behaviors*;
  let `is_boss` compose. (Revisit if bosses need genuinely unique logic.)
- **Resolution: B, reframed (2026-06-21k).** Owner walked the full taxonomy (§2a) and the
  result is **two orthogonal axes + a `target_policy` modifier**, not a flat enum. `boss` is
  NOT a profile — `is_boss` (already on placements; existing boss `e8_knight_boss` is authored
  `ai_profile:"basic"` + `is_boss:true`) **composes** onto any disposition: sitting boss =
  `guard_tile` + `is_boss` + throne; hunting boss = `basic` + `is_boss`. **MVP profile set
  grew** past the original two to `territorial` + `guard_tile` + `patrol` + `flee` + the
  `target_policy` modifier (owner pulled `flee`, `patrol`, and `focus_weakest` into MVP).

### [AIP-2] Leash/anchor data: where does `home_tile` + radii live?  **[RESOLVED → A + C default]**
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
- **Resolution: A + C default (2026-06-21k).** Optional `enemy_placements` keys — `home_tile`
  (default spawn tile), `aggro_radius`, `leash_radius` — alongside the existing `ai_profile`/
  `is_boss`/`faction` keys. The `target_policy` modifier ([AIP-1]/§2a) is a sibling placement
  key (default `"nearest"`). All thresholds default via `GameConstants` ([AIP-4]) so most
  authoring is just `ai_profile: "territorial"`. `UnitData` and its snapshot contract stay
  clean — none of this is unit-intrinsic.

### [AIP-3] Aggro/leash semantics: latch or re-evaluate?  **[RESOLVED → both, as two profiles]**
Once a `territorial` unit wakes, does it stay awake?
- **A — Latch on wake** (once a player enters aggro radius, the unit becomes `basic`
  permanently). Simple, predictable, classic FE "the room woke up."
- **B — Re-evaluate each turn** (returns home / re-sleeps if all players leave the leash).
  More dynamic, but can produce a unit that oscillates at the leash boundary.
- **Rec: A** — latching matches the FE feel and is far easier to reason about (and to test
  deterministically). Returning-home (B) is a polish behavior that can be added per-profile
  later if a map wants a true patrol. The wake-latch state is per-map runtime → reserve a
  snapshot field ([AIP-5]).
- **Resolution: BOTH — as two distinct profiles (2026-06-21k).** `territorial` = **A (latch)**
  — woken room stays awake, deterministic, `ai_awake` persisted ([AIP-5]). `patrol` = **B
  (re-evaluate)** — returns home / re-sleeps when players leave `leash_radius`. Keeping them
  as separate profiles (rather than one profile with a mode flag) keeps `territorial` dead
  simple and gives authors an explicit choice. **Owner pulled `patrol` into MVP**, so B ships
  now as its own profile rather than as a deferred polish behavior.

### [AIP-4] Data-driven thresholds vs hardcoded  **[RESOLVED → B]**
- **A — Author radii per placement** ([AIP-2]); no global constants.
- **B — Global defaults in `GameConstants`** (e.g. `DEFAULT_AGGRO_RADIUS`) with per-placement
  override. Less authoring per unit.
- **Rec: B** — a sensible global default (aggro ≈ unit movement + weapon range) means
  authors usually set nothing; override only the special cases. Matches how the codebase
  already centralizes tunables in `GameConstants`.
- **Resolution: B (2026-06-21k).** `GameConstants.DEFAULT_AGGRO_RADIUS` /
  `DEFAULT_LEASH_RADIUS` (aggro ≈ movement + weapon range) as defaults; per-placement keys
  override ([AIP-2]). Centralizes the tunables for balance passes and keeps per-unit authoring
  to near-zero. `retreat_hp_pct` (for the fast-follow `retreat_when_low`) gets the same
  treatment when it lands.

### [AIP-5] Wake-state persistence (snapshot interaction)  **[RESOLVED → A]**
The latched "awake" flag ([AIP-3] → A) is mutable per-map state — Retry/suspend must
restore it or a reloaded map could re-sleep a woken room.
- **A — Add an `ai_awake: bool` to the unit snapshot** (mirrors the `UnitData` snapshot
  contract note); recompute nothing.
- **B — Recompute wake state from positions on load** (a unit is awake if a player is/has
  been in range — but "has been" isn't derivable, so this under-restores).
- **Rec: A** — wake is a latched memory, not derivable from current positions; it must be
  serialized. One bool per unit; reserve it in the §2 schema (this register's only §2 ask).
  Update `test_snapshot_coverage` STATIC_FIELDS accordingly.
- **Resolution: A (2026-06-21k).** `ai_awake: bool` per unit in the snapshot — the register's
  **only new §2 field**. Applies to `territorial` (latched) only; `patrol` re-evaluates from
  positions each turn so it needs no saved state (a `patrol` unit's home is its placement
  `home_tile`, already authored). Reserve `ai_awake` in the §2 schema and add it to
  `test_snapshot_coverage` STATIC_FIELDS when the field lands.

## 4. Slice sketch (revised 2026-06-21k — MVP = 4 profiles + target_policy)
1. **Validator + data keys.** `_VALID_AI_PROFILES` += `territorial`, `guard_tile`, `patrol`,
   `flee`; add a `_VALID_TARGET_POLICIES = ["nearest", "weakest"]` validated set. New optional
   `enemy_placements` keys: `home_tile`, `aggro_radius`, `leash_radius`, `target_policy`.
   `GameConstants.DEFAULT_AGGRO_RADIUS`/`DEFAULT_LEASH_RADIUS` ([AIP-4]). **DoD#2:** extend the
   boot validator (`DataManager`) AND add a `check_docs` guard mirroring the profile +
   target-policy value-sets (same pattern as the `mouse_cursor`/movement-type checks).
2. **`_act_guard_tile`** — pinned `passive` anchored on `home_tile` (default spawn).
3. **`_act_territorial`** — sleep at home → latch awake when a player enters `aggro_radius` →
   delegate to `basic`; `ai_awake` snapshot field ([AIP-5]).
4. **`_act_patrol`** — non-latching sibling: wake like territorial, but return toward
   `home_tile` / re-sleep when all players leave `leash_radius` (no saved state).
5. **`_act_flee`** — move to maximize distance from the nearest threat within movement range;
   never attack (inverse of the `_find_nearest`/`_choose_move_tile` pursuit math).
6. **`target_policy` modifier** — thread through the target-selection step (`_find_nearest`
   call sites) so `weakest` focus-fire applies to `basic`/`territorial`/`patrol`/`guard_tile`.
7. **`is_boss` compose** — `guard_tile` + throne-bonus, no new profile ([AIP-1]).

## 5. Test notes
- Extend `test_enemy_ai`: `guard_tile` never leaves `home_tile`; `territorial` stays put until
  a player enters `aggro_radius`, then closes, and **stays awake** across a later turn even if
  the player retreats (latch); `patrol` wakes the same way but **returns home / re-sleeps**
  when players leave `leash_radius`; `flee` increases its min-distance-to-threat each turn and
  never initiates combat; `target_policy: "weakest"` picks the killable/lowest-def target over
  the nearest.
- `test_data_manager`: unknown `ai_profile` still rejected; the 4 new profiles accepted;
  unknown `target_policy` rejected, `nearest`/`weakest` accepted.
- `test_snapshot_coverage`: `ai_awake` covered.

## 6. Buckets & forward items (from §2a)
- **MVP (this build):** `territorial`, `guard_tile`, `patrol`, `flee`, `target_policy`
  (`nearest`+`weakest`), `is_boss` compose.
- **Fast-follow (ungated):** `retreat_when_low` (+`retreat_hp_pct`), `kite` (avoid-counter
  tile scoring), `hunt:<unit_id>` target policy.
- **Gated (land with parent feature, each as a new profile here — one taxonomy):**
  `fog_scout` (FOW [FOW-3]→C) · `chest_looter` (DCH [DCH-4]→B) · `siege_operator`
  (STW [STW-6]→B) · `buffer` (M9 staves) · `thief_steal` (steal mechanic) · `dancer`.
