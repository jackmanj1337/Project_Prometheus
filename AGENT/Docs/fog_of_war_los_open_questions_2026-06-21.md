# Fog of War / Line-of-Sight (§5) — Draft Plan + Open Questions Register

**Started:** 2026-06-21d
**Status:** Planning draft — register OPEN. Substantial new system.
**Source:** `planning_backlog_2026-06-20.md` §5; session note 2026-06-21c Tier 1 #3.
**Ties to:** §2 suspend (per-faction visibility must serialize), §4 map-readability
(reveal overlay shares the overlay infra), `EnemyAI` (AI knowledge under fog).
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)

- **`UnitData.line_of_sight: int = 4`** already exists (line 33) — authored per unit,
  default 4. **Nothing reads it today.** This is the vision-radius input fog will consume.
- **`MapData` carries a save-system TODO** (top of file): runtime terrain mutation /
  visibility is explicitly called out as not-yet-snapshotted. Fog visibility is per-faction
  runtime state that the §2 save must capture.
- **Terrain model is string-grid based.** `GridManager.get_terrain_at(tile)` returns a
  terrain code; `TERRAIN_DEF_BONUS`/`TERRAIN_DODGE_BONUS` exist. Fog needs a *vision-cost*
  or *blocks-sight* terrain property — **not present** (forests/walls don't yet impede sight).
- **Overlay infra** (`_overlay` TileMapLayer, `_paint_overlay`) can render a fog/unseen
  mask, but there is no "hidden tile" source today.
- **Enemy spawning is full-knowledge.** `GameMap._spawn_units` respawns all enemies; the
  HUD and `EnemyAI` see every unit. Fog requires a per-faction "known units" filter at the
  render + AI layers.
- **`EnemyAI`** targets via `_living_hostiles_for_faction` (sees all). Under fog, the AI
  must either respect the same vision rules or be exempt — see [FOW-3].

## 2. Draft plan (classic FE convention)

Fire Emblem fog (FE3 "Fog of War", GBA, Conquest) convention:
- The map is dark except tiles within **any deployed allied unit's vision radius**.
- **Vision radius** = the unit's stat (here `line_of_sight`), often **+1 on a fort/some
  terrain**, reduced at night in some titles.
- **Enemies are invisible until seen**; stepping a tile adjacent can reveal an ambush.
- Thieves/scouts have **higher vision**; torches/lanterns are consumable vision items.
- **AI under fog**: classic FE enemies on fog maps typically *do* have full knowledge
  (they "cheat") OR are scripted — true symmetric fog for AI is rare. This is the headline
  design decision ([FOW-3]).

Core model: a per-faction `visible_tiles: Dictionary` recomputed at the start of that
faction's phase (and after each of its units moves) as the union of each living unit's
LoS disc. Render = dim/hide tiles not in the active viewer's set; hide enemy unit nodes
on unseen tiles.

## 3. Open questions register

### [FOW-1] Visibility model: radius vs true line-of-sight  **[OPEN]**
- **A — Simple radius (Manhattan/Chebyshev disc)**, terrain does NOT block sight. Matches
  GBA-FE fog (vision is a pure range; forests don't occlude). Cheapest; reuses
  `_tiles_in_range`-style math.
- **B — True LoS with terrain occlusion** (walls/forest block sight beyond them;
  raycast/shadowcast per tile). Tactically richer, much heavier, needs a "blocks_sight"
  terrain property added to the terrain model.
- **Rec: A** — GBA-FE (the project's evident touchstone) uses radius fog, not occlusion;
  it's far cheaper for the web/mobile target and `line_of_sight` is already a flat radius.
  Reserve B as a later per-map opt-in if a design wants it.
- **Resolution:** _[OPEN]_

### [FOW-2] Fog is per-map opt-in, or a global rule?  **[OPEN]**
- **A — Per-`MapData` flag (`fog_enabled: bool`)** — fog is a property of a map, authored
  per scenario. Classic FE: specific chapters are fog chapters.
- **B — `CampaignRules` toggle** — fog on/off for the whole run.
- **C — Both:** map declares fog; a campaign rule may force-disable (accessibility).
- **Rec: A** (with C's force-off later) — fog is a per-chapter design choice in FE, not a
  run-wide mode. A `MapData.fog_enabled` field (default false) means existing maps load
  unchanged. Composes with §2's per-map data fields.
- **Resolution:** _[OPEN]_

### [FOW-3] AI knowledge under fog — the headline decision  **[OPEN]**
- **A — AI cheats (full knowledge).** Enemies path/target as today, ignoring fog; only the
  *player's* view is fogged. Matches most classic FE fog maps; zero `EnemyAI` change.
- **B — AI respects fog symmetrically.** `EnemyAI` only sees player units inside red's
  vision set; un-spotted players are safe. Fairer, far more complex (AI needs a
  "last-known-position" memory + search behavior), and can feel passive/exploitable.
- **C — Per-profile:** most enemies cheat (A); a future "scout/patrol" profile respects
  fog (ties to §5 AI-profiles item).
- **Rec: A** — symmetric fog AI is a large, risky behavior system that classic FE itself
  mostly avoids; cheating AI is the genre norm and keeps `_living_hostiles_for_faction`
  untouched. Note C as a future scout-profile hook (cross-ref the AI-profiles register).
- **Resolution:** _[OPEN]_

### [FOW-4] Vision recompute cadence + reveal-on-move  **[OPEN]**
- **A — Recompute the active faction's visible set at phase start + after every committed
  move** (so walking forward reveals tiles mid-move, enabling ambush reveals).
- **B — Phase-start only** (cheaper; no mid-move reveal — the player must end the turn to
  see what a move uncovered).
- **Rec: A** — mid-move reveal is the *point* of FE fog (the ambush moment); recompute is
  one LoS-disc union per move, cheap at A's radius model. Reveal an enemy → pause/announce
  (reuse the `ai_unit_acting` camera-pan pattern for "enemy spotted").
- **Resolution:** _[OPEN]_

### [FOW-5] Save/suspend interaction (forward dep on §2)  **[OPEN]**
Per-faction visibility + "which enemies has the player discovered" is runtime state.
- **A — Serialize the discovered-enemy set + recompute live visibility on load.** Save only
  *which units the player has ever spotted* (small); the visible-tile mask is recomputed
  from unit positions at load. Minimal save growth.
- **B — Serialize the full visible-tile mask per faction.** Larger, exact, but redundant
  (derivable from positions).
- **Rec: A** — visibility is a pure function of unit positions + LoS, so only the
  *discovered* memory (the bit that ISN'T derivable) needs saving. Reserve a
  `discovered_units` field in the §2 schema (this register's only §2 ask).
- **Resolution:** _[OPEN]_

### [FOW-6] Vision modifiers: terrain + items  **[OPEN]**
- **A — `line_of_sight` only, no modifiers** (flat per-unit radius). Ship the minimum.
- **B — Terrain bonus** (e.g. +1 LoS on forts/peaks, like FE) via a `TERRAIN_VISION_BONUS`
  dict mirroring the existing bonus dicts.
- **C — B + consumable torch/lantern items** (an `ItemData` effect granting temp vision).
- **Rec: A for v1, design B/C as fast-follows** — ship flat radius fog working end-to-end
  first; terrain vision + torches are additive and slot cleanly onto the existing
  `TERRAIN_*_BONUS` + `ItemHandler` patterns once the core works.
- **Resolution:** _[OPEN]_

## 4. Slice sketch (provisional)
1. `MapData.fog_enabled` + per-faction visibility computation (radius union of `line_of_sight`).
2. Render: fog mask overlay + hide enemy nodes on unseen tiles (player view only).
3. Reveal-on-move ([FOW-4]) + "enemy spotted" feedback.
4. AI cheats (no `EnemyAI` change — verify it ignores fog) ([FOW-3] → A).
5. Save: `discovered_units` reserved in §2 schema ([FOW-5]).
6. (Fast-follow) terrain vision + torch items ([FOW-6]).

## 5. Test notes
- Headless: assert the visible-tile union for a fixed unit layout + `line_of_sight`; assert
  an enemy on an unseen tile is filtered from the player's render list but NOT from
  `EnemyAI` target lists (proves [FOW-3] → A).
- Reveal: move a unit one tile, assert a previously-hidden enemy enters the discovered set.
