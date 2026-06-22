# Additional AI Profiles (§5) — Draft Plan + Open Questions Register

**Started:** 2026-06-21d
**Status:** RESOLVED 2026-06-21k — all of `[AIP-1..5]` resolved + a full canonical profile
target list drafted (§2a). MVP grew past the original two profiles. Build-ready (the `ai_awake`
save field rides §2). Extends an existing system; contained.
**Source:** `planning_backlog_2026-06-20.md` §5; session note 2026-06-21c Tier 2 #4.
**Companion:** `GDD_08_Enemy_AI.md`. **Code:** `scripts/core/EnemyAI.gd`.
**MVP profile set (owner-chosen):** `territorial` + `guard_tile` + `tethered` + `flee`, plus a
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
| `tethered` | like `territorial` but **non-latching** — returns home / re-sleeps when players leave `leash_radius` | **MVP** | same leash keys; no latch |
| `flee` | every turn move to maximize distance from nearest threat; never engage (villagers, runners, cowards) | **MVP** | none (inverse pursuit) |
| `seek_tile` | advance toward an authored **goal tile** (e.g. seize the player's throne), engaging nearest en route — the Defend-chapter attacker | **MVP** *(owner pulled in 2026-06-22c, [AIP-8])* | `goal_tile` |
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
- **MVP (this register builds):** `territorial`, `guard_tile`, `tethered`, `flee`, **`seek_tile`**
  + the `target_policy` modifier (`nearest`+`weakest`) + `is_boss` compose + **event-driven
  activation & the MET `set_ai` action** ([AIP-8] pulled the §8 gap-1/gap-2 capabilities into MVP).
- **Fast-follow (ungated, build anytime):** `retreat_when_low`, `kite`, `hunt` target policy,
  true route-patrol.
- **Gated (land with parent feature):** `fog_scout` (FOW) · `chest_looter` (DCH) ·
  `siege_operator` (STW) · `buffer` (M9 staves) · `thief_steal` (steal mech) · `dancer`.

## 2b. Starter preset library — RESOLVED [AIP-7] *(2026-06-22c)*

The presets-first authoring surface (vision §2). A **preset** = a named bundle over the three
axes; authors write `ai: "<preset>"` and override one axis for special cases. Flavor names kept
(owner: "keep them"). `sentry` collapsed into `guard` (owner) — `passive` + `guard_tile` are one
`hold_tile` disposition differing only in `home_tile` default.

| Preset | Activation | Disposition | Engagement | = profile |
| --- | --- | --- | --- | --- |
| `grunt` | always | pursue_unit | nearest | basic |
| `guard` | always | hold_tile (`home_tile` = spawn unless authored) | nearest | passive/`guard_tile` unified (+`is_boss`→throne) |
| `sleeper` | proximity (latch) | pursue when awake | nearest | territorial |
| `tethered` | proximity (no latch) | pursue / return-home | nearest | tethered |
| `coward` | always | flee (from threat) | — | flee |
| `runner` | always | flee → `goal_tile` | — | flee + goal_tile |
| `raider` | always | seek_tile (`goal_tile`) | nearest | seek_tile (Defend-chapter attacker) |
| `hunter` | always | pursue_unit | **weakest** | basic + focus-fire |
| `healer` | always | reach injured ally | heal | (existing) |

*(`raider` added 2026-06-22c with [AIP-8]; working name — rushes a goal tile, engaging en route.
Mirror of `runner`, which flees toward a goal tile. 9 presets total now.)*

**Composition precedence** (later overrides earlier): base preset → placement axis override →
group inheritance → difficulty overlay. Conflict rules: an override replaces **only its axis**;
`target_policy` layers onto any *targeting* disposition; **`flee` ignores `target_policy`** (it
isn't engaging).

**Runtime profile change is a first-class authoring tool (owner requirement, 2026-06-22c):** a
campaign author can **change a unit's or group's preset/axes on an event trigger** via a MET
**`set_ai`** action (e.g., "on turn 5 the `guard` squad becomes `grunt`"; "when the boss dies the
survivors become `coward`"). This generalizes the gap-1 event-aggro "wake" (waking = `set_ai`
changing only the Activation axis). Mechanically clean in the composition engine: `set_ai`
overrides the unit/group `AISpec`; the planner reads the new spec on the next activation (activation
already reads event state — vision §4 rule 3). → confirmed MET action (see [MET-3] note + [AIP-15]).

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
  grew** past the original two to `territorial` + `guard_tile` + `tethered` + `flee` + the
  `target_policy` modifier (owner pulled `flee`, `tethered`, and `focus_weakest` into MVP).

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
  — woken room stays awake, deterministic, `ai_awake` persisted ([AIP-5]). `tethered` = **B
  (re-evaluate)** — returns home / re-sleeps when players leave `leash_radius`. Keeping them
  as separate profiles (rather than one profile with a mode flag) keeps `territorial` dead
  simple and gives authors an explicit choice. **Owner pulled `tethered` into MVP**, so B ships
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
  **only new §2 field**. Applies to `territorial` (latched) only; `tethered` re-evaluates from
  positions each turn so it needs no saved state (a `tethered` unit's home is its placement
  `home_tile`, already authored). Reserve `ai_awake` in the §2 schema and add it to
  `test_snapshot_coverage` STATIC_FIELDS when the field lands.

## 4. Slice sketch (revised 2026-06-22c — MVP now incl. `seek_tile` + event-activation, [AIP-8])
1. **Validator + data keys.** `_VALID_AI_PROFILES` += `territorial`, `guard_tile`, `tethered`,
   `flee`, **`seek_tile`**; add `_VALID_TARGET_POLICIES = ["nearest", "weakest"]`. New optional
   `enemy_placements` keys: `home_tile`, `aggro_radius`, `leash_radius`, `target_policy`,
   **`goal_tile`**, **`group_id`**. `GameConstants.DEFAULT_AGGRO_RADIUS`/`DEFAULT_LEASH_RADIUS`
   ([AIP-4]). **DoD#2:** extend the boot validator (`DataManager`) AND add a `check_docs` guard
   mirroring the profile + target-policy value-sets (same pattern as `mouse_cursor`/movement-type).
2. **`_act_guard_tile`** — pinned `passive` anchored on `home_tile` (default spawn).
3. **`_act_territorial`** — sleep at home → latch awake when a player enters `aggro_radius` (or on
   damage taken, §7) → delegate to `basic`; `ai_awake` snapshot field ([AIP-5]).
4. **`_act_tethered`** — non-latching sibling: wake like territorial, but return toward
   `home_tile` / re-sleep when all players leave `leash_radius` (no saved state).
5. **`_act_flee`** — move to maximize distance from the nearest threat within movement range;
   never attack (inverse of the `_find_nearest`/`_choose_move_tile` pursuit math); optional
   `goal_tile` → flee *toward* it (`runner`).
6. **`_act_seek_tile`** *(MVP via [AIP-8])* — advance toward `goal_tile`, engaging nearest en route
   (the `raider`/Defend-chapter attacker). Reuses the disposition planner's unit-or-tile target
   abstraction (vision §4 rule 2).
7. **Event-driven activation + `set_ai`** *(MVP via [AIP-8])* — activation reads an event/flag, and
   a MET **`set_ai`** action overrides a unit's/`group_id`'s `AISpec` at runtime (the proximity↔
   event-aggro bridge). Planner reads the new spec next activation (vision §4 rule 3).
8. **`target_policy` modifier** — thread through the target-selection step (`_find_nearest`
   call sites) so `weakest` focus-fire applies to any targeting disposition.
9. **`is_boss` compose** — `guard_tile` + throne-bonus, no new profile ([AIP-1]).

## 5. Test notes
- Extend `test_enemy_ai`: `guard_tile` never leaves `home_tile`; `territorial` stays put until
  a player enters `aggro_radius`, then closes, and **stays awake** across a later turn even if
  the player retreats (latch); `tethered` wakes the same way but **returns home / re-sleeps**
  when players leave `leash_radius`; `flee` increases its min-distance-to-threat each turn and
  never initiates combat; `target_policy: "weakest"` picks the killable/lowest-def target over
  the nearest.
- `test_data_manager`: unknown `ai_profile` still rejected; the 4 new profiles accepted;
  unknown `target_policy` rejected, `nearest`/`weakest` accepted.
- `test_snapshot_coverage`: `ai_awake` covered.

## 6. Buckets & forward items (from §2a)
- **MVP (this build):** `territorial`, `guard_tile`, `tethered`, `flee`, `target_policy`
  (`nearest`+`weakest`), `is_boss` compose.
- **Fast-follow (ungated):** `retreat_when_low` (+`retreat_hp_pct`), `kite` (avoid-counter
  tile scoring), `hunt:<unit_id>` target policy.
- **Gated (land with parent feature, each as a new profile here — one taxonomy):**
  `fog_scout` (FOW [FOW-3]→C) · `chest_looter` (DCH [DCH-4]→B) · `siege_operator`
  (STW [STW-6]→B) · `buffer` (M9 staves) · `thief_steal` (steal mechanic) · `dancer`.

## 7. MVP-spec refinements — RATIFIED 2026-06-22c (was "held") *(2026-06-21k → 2026-06-22c)*

Four refinements surfaced when walking the profiles in detail; held 2026-06-21k, **all four
RATIFIED 2026-06-22c as [AIP-6]** ("good for starting points"), with the return-home profile
**renamed `patrol` → `tethered`** (working name; consistent with the `leash_radius` field, avoids
the route-walker connotation of "patrol").

1. **`territorial` wakes when attacked (not just proximity).** Wake trigger = a player enters
   `aggro_radius` of `home_tile` **OR** the unit took damage since its last activation; and
   `aggro_radius` should be ≥ attack range so a sleeping archer can't passively snipe without
   waking. *(RATIFIED.)*
2. **`tethered` (renamed from `patrol`) = leashed return-home, explicitly NOT a waypoint
   route-walker.** v1 `tethered` wakes on proximity and walks back to `home_tile` when disengaged.
   A true route-patrol (walks an authored beat A→B→C while idle) is a richer, separate behavior →
   deeper fast-follow. *(RATIFIED + renamed.)*
3. **`flee` optional `goal_tile`.** With `goal_tile` = escape *toward* an exit (avoiding
   threats); without = pure run-away. Covers escape-map runners / loot-carriers in MVP. This
   is the same "move toward an authored tile" primitive Gap #2 (§8) needs. *(RATIFIED.)*
4. **`target_policy: "weakest"` concrete metric.** Define as: prefer a target it can **KO this
   activation** (forecast-lethal); else the one it deals the most **proportional** damage to.
   Must thread through the **move-tile choice** too (move to where you can hit the weakest),
   not just the final target pick. *(RATIFIED.)*

## 8. Gap analysis — FE archetypes/scenarios the current plan can't yet express *(2026-06-21k)*

Pressure-tested the resolved taxonomy + the sibling registers (MET events, DCH doors/chests,
DTR destructible, FOW fog, M16 objectives, M14 factions) against the Fire Emblem catalog. The
*disposition* axis is essentially complete; the gaps cluster in three layers. **Update
2026-06-22c ([AIP-8]): Layers 1 & 2 are now pulled into the FIRST AI build** ("make them
available"); Layer 3 remains a separate later workstream.

### Layer 1 — Activation beyond proximity *(biggest gap; rides MET)* — **NOW MVP ([AIP-8])**
Our wake model (`territorial`/`tethered`) is **proximity-only**. A huge fraction of FE maps use
**event/turn-driven aggression**: "on turn 6 the whole army charges," "after you cross the
bridge the boss's squad activates" — regardless of player position. **Not expressible today:**
MET actions are `reveal_tiles`/`flag`/`spawn` (no wake/profile-change action), and `territorial`
only checks proximity, not a flag. **Fix (small, rides MET):** either a MET `set_aggro`/`wake`
action, or have `territorial`/`tethered` honor a map-flag as an alternate wake trigger so a
`turn_reached`→`flag` event wakes the room. *Design the proximity-aggro ↔ event-aggro bridge.*
→ also a **MET cross-ref** (new candidate action).

### Layer 2 — Goal-tile / objective-seeking movement *(rides the encounter layer)* — **NOW MVP ([AIP-8])**
Every planned disposition targets enemy **units**. FE has two big patterns that target **tiles**:
- **Defend chapters** — enemies rush *your* throne/point to seize it ("advance to objective
  tile and seize"). No disposition for it; `basic` only chases units.
- **Escape AI** — an NPC sprints for the exit, or an enemy flees *with loot* toward a map edge.
  This is the held `flee` + `goal_tile` refinement (§7.3).

Both are the same missing primitive: **move toward an authored goal tile** (offensive seek or
defensive escape). Connects to the FOW [FOW-2] encounter-layer idea — a Defend scenario is the
same terrain as an Assault with the AI's goal tile flipped. → candidate new disposition
(`seek_tile` / `advance`) + the `flee goal_tile` variant.

### Layer 3 — Per-engagement combat sophistication *(a SEPARATE workstream from profiles)*
Profiles are movement/disposition; FE AI is also smart *inside one engagement*. Barely speced:
- **Weapon selection** — FE AI auto-equips the *best* weapon per fight (armorslayer vs knights,
  effective bow vs fliers). Ours uses the equipped weapon. Big difficulty lever.
- **Trade evaluation / cautious AI** — FE AI often *declines* a bad attack (won't suicide into a
  counter). `kite` only addresses range; no general "skip an unfavorable attack." Ours always
  attacks if able.
- **Item-use AI** — drink a vulnerary when hurt. `retreat_when_low` only moves; doesn't self-heal.
- **Value-based targeting** — even `weakest` is cruder than FE's "pick the engagement that does
  the most damage / secures a kill across all reachable targets." Default `nearest` is crude.
→ This is a **"combat AI" layer distinct from "profiles"** — a future workstream of its own.

### Smaller / asterisked
- **HP-threshold triggers** ("boss enrages at half HP," summoner phases) — MET has
  `unit_died`/`turn_reached`/`object_broken` but **no `unit_hp_below`** trigger. Summoners
  mostly work via `turn_reached`→`spawn`; the HP-reactive flip needs a new MET trigger. → MET cross-ref.
- **Ambush spawns** (spawn *and act* same turn) — depends on whether MET's `spawn` action can
  flag "acts immediately." Confirm in the MET spec. → MET cross-ref.
- **Berserk / status-staff AI** — gated on M8/M9 content, but **berserk also breaks
  `_living_hostiles_for_faction`** (it attacks *all* factions incl. its own) — a targeting-model
  gap, not just content.
- **AI opening doors / breaking walls to pursue** — deferred by plan (DCH no-AI-loot, [DTR-7]
  no-AI-break v1). "Enemies smash through to swarm you" is a known v1 omission.
- **Escort/follow** (stay near a protected NPC) and **lure/bait** (retreat to pull you in) —
  niche; no home yet, minor.

**Summary:** disposition axis ✓. Three real gaps FE leans on heavily — **(1) event/turn-driven
aggression (MET↔aggro bridge), (2) goal-tile seeking (Defend + escape maps), (3) per-engagement
combat smarts (weapon/item/trade)**. (1) and (2) are small and ride already-designed systems;
(3) is a genuinely separate "combat AI" workstream. Revisit all three when firming the AI design.

> **Build spec (2026-06-22c):** Group A is complete — the resolved decisions `[AIP-1..10]` +
> `[AIP-A11/A12]` are synthesized into one implementable design at
> **`AGENT/Docs/ai_first_build_design_2026-06-22.md`** (architecture, data model, presets,
> behaviors, `set_ai`/grouping, build slice + tests, deferred seams). Build that against Package A.

## 9. Design vision (player-facing + campaign-builder + architecture) *(2026-06-22a)*
The forward vision that this register's MVP must not paint into a corner is captured in
**`AGENT/Docs/ai_system_design_vision_2026-06-22.md`**: AI as a **composition engine** (Activation
/ Disposition / Engagement axes + grouping + difficulty), profiles as **presets**, **author-
defined difficulty bands** (modifier overlays on the encounter layer), **presets-first data
authoring** (branch I), and **disposition visible by default** + an opt-in tutorial/easy action-
preview. Each §8 gap = "extend one axis." The doc's §4 lists the four cheap "don't-paint-into-a-
corner" rules the MVP AIP build should honor (profiles resolve to an `AISpec`; disposition target
is unit-or-tile; activation reads an optional flag; engagement is a function seam).

## 10. Open decisions register — continued ([AIP-6..], opened 2026-06-22c)

Audit (2026-06-22c) of every still-open AI decision. `[AIP-1..5]` are RESOLVED (MVP profiles
build-ready); these are what remains before the cluster is "finished." **Group A blocks the first
AI build; Group B blocks the full vision (post-MVP).** New/homeless items recorded here per the
governance rule (every open thread needs a home).

### Group A — blocks the first AI build — **COMPLETE 2026-06-22c** ([AIP-6..10] + the two A11/A12 build-time sub-items below)
- **[AIP-6]** Ratify the four held §7 MVP-spec refinements. **[RESOLVED 2026-06-22c]** — all four
  adopted as written ("good for starting points"), with the return-home profile **renamed
  `patrol` → `tethered`** (working name). See §7 (now ratified).
- **[AIP-7]** Starter preset library + composition-precedence rules. **[RESOLVED 2026-06-22c]** —
  8 presets (`grunt`/`guard`/`sleeper`/`tethered`/`coward`/`runner`/`hunter`/`healer`), flavor names
  kept, `sentry` collapsed into `guard`; precedence base→placement→group→difficulty, `flee` ignores
  `target_policy`. **Plus owner requirement: runtime profile change via a MET `set_ai` action.**
  Full table + rules in §2b.
- **[AIP-8]** §8 gap-scope. **[RESOLVED 2026-06-22c — BOTH in the first build]** ("let's make them
  available"). Gap 1 (event/turn aggression) ships via the confirmed MET `set_ai` action + event/
  flag-driven activation; gap 2 (goal-tile seeking) ships as the new **`seek_tile` disposition**
  (preset `raider`) + the already-ratified `flee goal_tile` (`runner`). Enlarges the first AI build
  but unlocks Defend chapters + scripted activation from day one.
- **[AIP-9]** Reinforcement-unit AI config. **[RESOLVED 2026-06-22c]** — MET-`spawn`ed units carry
  the **same AI keys** as a normal `enemy_placements` entry (preset/`ai_profile`, `group_id`,
  `home_tile`, `goal_tile`, …), plus **`act_on_spawn: bool` (default false)**; `true` = the FE
  ambush spawn (acts the turn it arrives). Resolves the MET spawn-acts-immediately asterisk.
- **[AIP-10]** Allied / green-NPC AI. **[RESOLVED 2026-06-22c]** — allied AI factions use the
  **same composition system, no special-casing**: author-assigned presets, targeting via the
  existing faction-relation lookup (`_living_hostiles_for_faction` is already relation-based, not
  hardcoded to "player"). A green ally can be any preset and fights whoever its faction is hostile to.

**Build-time sub-items pulled into the first build by [AIP-8] (small schema details, not design forks):**
- **[AIP-A11]** **`set_ai` payload schema. [RESOLVED 2026-06-22c]** — `set_ai` targets **a unit id
  OR a `group_id`**, and its payload is a **partial `AISpec` patch** (any subset of preset /
  activation / disposition / engagement / target_policy / goal_tile). Only the named fields change;
  the rest of the resolved spec is untouched — so "wake a group" = `set_ai{ group_id, activation:
  active }` and a full role-swap = `set_ai{ group_id, preset: "coward" }`. One action covers wake,
  charge, retreat-script, and objective-flip.
- **[AIP-A12]** **`group_id` aggro semantics. [RESOLVED 2026-06-22c]** — **yes, the group wakes
  together**: any one member entering its `aggro_radius` **or** taking damage wakes the whole
  `group_id`. Wake is tracked **per-group** (the `ai_awake` latch is keyed by group for grouped
  units; ungrouped units latch individually). `tethered` groups re-evaluate per-group against
  `leash_radius`. This is the FE "the room wakes together" staple and what authors expect from a squad.

### Group B — blocks the full vision (post-MVP; several already framed in vision §5)
- **[AIP-11]** Difficulty band-modifier vocabulary + whether bands may touch activation/disposition
  or only stats/roster/engagement-tier. **[OPEN]** — vision §3/§5.
- **[AIP-12]** Action-preview gating surface (chapter flag / difficulty band / accessibility) +
  non-binding "may change" UX. **[OPEN]** — vision §5.
- **[AIP-13]** Disposition-indicator visual language (icons/labels for the default telegraph). **[OPEN]** — vision §5.
- **[AIP-14]** Combat-AI workstream (§8 gap 3) timing + engagement-tier ↔ difficulty-band coupling. **[OPEN]**.
- **[AIP-15]** MET growth specifics. **Mostly resolved:** `set_ai` action = CONFIRMED + first-build
  ([AIP-7]/[AIP-8]; schema now tracked as [AIP-A11]); spawn-acts-immediately = RESOLVED via
  `act_on_spawn` ([AIP-9]). **Still OPEN (Group B / later):** the **`unit_hp_below` trigger** for
  "boss enrages at half HP" / summoner phases. **[OPEN — `unit_hp_below` only]** — MET [MET-3].
- **[AIP-16]** AI Pair-Up / Rescue usage (do enemy factions use those mechanics? likely defer). **[OPEN]**.
- *(pointer)* AI turn-pacing / skip-AI-animation / AI move speed = UI/UX backlog, AI-adjacent, not this cluster.
- *(pointer)* ML faction-controller Option A = pre-1.0 consideration, vision §6.
