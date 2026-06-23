---
Type: plan
Status: DRAFT — CST-1..12 RESOLVED
Last verified: 2026-06-23
---

# Campaign / Save Cluster (§2) — Technical Implementation Plan (DRAFT)

**Started:** 2026-06-21
**Last verified:** 2026-06-21
**Status:** DRAFT — architecture firmed; `[CST-1..12]` RESOLVED (one `[CST-13]` deferred to §2
execution kickoff). **Execution is gated behind Package A (`RngService`) per [CST-12 → C]** —
Package A is the next build step and needs its own plan; §2 slices follow it. Otherwise build-ready.
**Player-facing scope (resolved, do not re-open):** `campaign_save_player_facing_firming_2026-06-21.md`.
**Open decisions:** `campaign_save_open_decisions_2026-06-21.md` (`[CST-n]` referenced inline).
**Reused designs:** `rng_determinism_design_2026-06-11.md` (rewind), `individual_threat_range_design_2026-06-21.md`
(suspend must carry `_watch_set`/`_danger_mode`), `campaign_rules_firming_notes_2026-05-25.md`.

---

## 0. What exists today (grounding, verified 2026-06-21)
- **No campaign loop.** `NewGameScreen` picks one map + 4 rules → `change_scene_to_file(GameMap)`.
  Victory → `GameOverScreen` (standings + Retry/Quit). No disk save, no next-map, no prep.
- **`GameState`** holds `player_roster: Array[UnitData]`, `party_gold`, `party_items` in memory
  between maps; rules are loose fields; `_map_start_snapshot` is an in-memory Retry snapshot via
  `_snapshot_unit_data()` (Vector2i + deep-copied `InventoryEntry` Resources — **not JSON-safe**).
- **`CampaignRules.gd`** is an unwired Resource stub mirroring the loose GameState rules.
- **`PairUpRegistry`** has `serialize()`/`restore()` (deep-copy Dict) — reusable for the save.
- **`MapData`** has `player_start_tiles`, `enemy_placements`, `reward_gold/items`, factions,
  objectives. Enemies are **respawned fresh** each load (`GameMap._spawn_units`) — suspend must
  serialize live enemy state.
- **`map_registry.json`** is a flat pick-list (campaign + dev/test maps mixed; `is_dev_only` flag
  exists). **`SettingsManager`** persists global prefs to `user://settings.cfg` via `ConfigFile`
  (the autoload-owns-disk pattern to mirror for `SaveManager`).

## 1. Target architecture (subject to [CST-n])
```
SaveManager (autoload)            ── file I/O, slot enumeration, export/import, hash  [CST-1]
  └─ SaveData (RefCounted)        ── to_dict()/from_dict(): the I/O-free seam         [CST-1]
       └─ SaveCodec (module)      ── UnitData/InventoryEntry/Vector ↔ JSON primitives [CST-2]
CampaignData (json + loader)      ── progression-graph nodes referencing map ids      [CST-3]
GameState.campaign_rules          ── consolidated CampaignRules; loose fields delegate [CST-4]
PrepScreen (scene)                ── deploy/bench/placement/save/launch
MapResultsScreen / GameOverScreen ── victory advance vs defeat multi-choice           [CST-7]
MainMenu: + Continue / Load Game  ── resume-most-recent + slot picker
```

## 2. Save schema (JSON, human-readable) — shape
Top-level keys (exact field set finalized by [CST-2]/[CST-9]):
- `format_version: int`, `save_label: String`, `integrity: {whole, protected}` hashes [CST-9]
- `_warning` strings on dangerous regions (rules) — tinkerer note (G2)
- `header: {chapter/map name, progress, playtime, last_saved, party {count,gold,lord}, badges}` [CST-10/B6]
- `campaign: {campaign_id, node_id (graph position), cleared_nodes[]}` [CST-3]
- `rules: {...CampaignRules..., rewind_charges_per_map, mandated_rules[]}` [CST-4/CST-6]
  (protected, hashed; `mandated_rules` records which were author-locked at creation)
- `party: {gold, items[], roster[ unit dicts ]}` — full roster (recruit/convoy = later data growth)
- `suspend: null | { turn, phase, faction_cursor (_active_faction_idx/_turn_order/_activation_mode),
  unit_states {unit_id: READY|DONE}, enemies[], cursor_tile, watch_set, danger_mode,
  pair_up_registry, rng {map_seed, history_hash}, rewind_charges_left }` [CST-8 → between-action]

Unit dict = JSON-primitive form of the unit fields (tile as `[x,y]`, inventory entries as dicts),
produced by `SaveCodec`. **[CST-2 → B]:** ONE serializer serves both save AND the Retry snapshot —
`_snapshot_unit_data`/`_restore_unit_data` are rebuilt onto the JSON-primitive codec, so the
`InventoryEntry` round-trip must be provably lossless (hard `test_save_codec` obligation; Retry
now depends on it).

## 3. Progression graph + campaign-owned rules [CST-3 → A/JSON][CST-5 → B][CST-6]
`CampaignData` (JSON) defines ordered nodes; each node: `node_id`, `map_id` (→ map_registry),
`required_units`/`excluded_units`/`deployment_cap` ([CST-5 → all on the node]), `next` (id or
list — linear = single successor). `player_start_tiles` stay on `MapData` as placement anchors.
MVP traverses linearly; the same structure later carries an overworld selector + branches +
interludes + side-quests with no schema reshape.

**Everything-is-a-campaign [CST-6]:** there is ONE flow (campaign select → prep → launch). Every
`map_registry` entry is auto-wrapped as a 1-node campaign (dev/test maps = `is_dev_only` campaigns,
filtered from the player list); authored multi-node campaigns are peers. **Campaign-owned rules:**
each `CampaignData` carries a rules block where each rule is an author **MANDATE** (locked) or a
**DEFAULT** (player-editable); `campaign_rules` is seeded from it at creation, the save records
which were mandated, and the rules UI locks mandates / lets the player edit defaults. The campaign
selector defaults to last-started, else most-recently-imported.

## 4. Flows
- **New Game** [CST-6]: campaign selector (defaults to last-started/most-recently-imported) →
  rules screen (mandated locked, defaults editable) → `SaveManager.new_campaign()` →
  PrepScreen(node 1). No separate debug launcher — test maps are `is_dev_only` 1-node campaigns.
- **Prep** (C1–C3): show required (forced) + roster minus excluded; player deploys up to
  `deployment_cap`, assigns placement onto `player_start_tiles`; manual Save; Begin Battle →
  GameMap. Benched units gain nothing.
- **Victory** [CST-7 → A]: new `MapResultsScreen` (standings) → advance `node_id` → autosave →
  next PrepScreen (or campaign-complete). The standings/rankings renderer is **kept as a reusable
  component** (future PvP scenario mode — §9).
- **Defeat** [CST-7/B5]: GameOverScreen refit as the multi-choice menu — reload recent / reload any (slot picker) /
  main menu / [Rewind] (shown only when rule on; charge count; grey at 0) [CST-12].
- **Continue** (A4): `SaveManager.last_played` → resume suspend if newest is a suspend, else load
  latest between-map save into Prep. **Load Game**: slot picker (B6 rows).
- **Suspend** [CST-8 → between-action]: offered in idle FREE state between committed actions while
  the active faction is human-driven (incl. F9 hotseat enemy phase); persistent + re-loadable.

## 5. Mid-battle suspend [CST-8 → between-action, human-controlled] — the hard part
Beyond the player Retry snapshot, suspend must serialize **live enemy UnitData + positions**
(respawned fresh today), turn #, phase, the activation cursor (`_active_faction_idx`/`_turn_order`/
`_activation_mode`), per-unit `_unit_states` (`{unit_id: READY|DONE}`), cursor tile, threat-range
`_watch_set`/`_danger_mode` (forward dep — `individual_threat_range_design` §5/slice 4), pair-up
registry (reuse `PairUpRegistry.serialize`), and RNG `{map_seed, history_hash}`. Restore rebuilds
the board from this instead of `_spawn_units`' fresh placements.

**Gate:** offered only in the **idle FREE cursor state between committed actions**, while the
active faction is **human-driven** — so F9 hotseat override yields mid-enemy-phase suspend for
free (same idle boundary). The between-action delta over a phase-start save is just `_unit_states`
+ the activation cursor; both already live on `TurnManager`. **Excluded** (needs Package A
replay): mid-move/animation/attack-resolution + AI-driven enemy phases. **Tests:** ALTERNATING
mid-round restore, mixed READY/DONE restore, enemy-board-from-state restore.

## 6. Rules consolidation + story-flip [CST-4 → B][CST-11]
`GameState.campaign_rules: CampaignRules` is the single source of truth; **every call site is
hard-migrated** to `gs.campaign_rules.<field>` and the loose GameState fields are deleted (no
shims) — chosen for the clean end state. Sweep size (verified 2026-06-21): ~70 refs total —
`pair_up_enabled` 26/15 files, `auto_promote_at_max_level` 14/6, `max_skills` 11/6,
`leveling_method` 9/6, `permadeath_enabled` 6/5, `max_inventory` 3/2, `exp_gaining_factions` 1/1.
Add `rewind_charges_per_map` (RNG-3 default 3–5, 0=ironman). Story-flip seam: `apply_rule_flip(rule,
value, reason)` records + emits `campaign_rule_flipped`; notification UI + read-only prep rules
view (G1) consume it. Trigger source (event system) deferred.

## 7. Robustness [CST-9 → A + author-designatable]
Two SHA-256 hashes: whole-file over canonical (sorted-key) JSON with the hash field excluded, and
a protected sub-hash over a **mandatory baseline** (`format_version`, rules incl. `mandated_rules`,
progression position) **plus any author-designated `CampaignData.protected_fields`**. The save
stamps the effective protected-field list so the loader recomputes over exactly those paths. Load =
warn-and-continue on whole-file mismatch, stronger secondary warning on protected mismatch, hard
fail only on unparseable JSON / unknown `format_version` the loader chooses to refuse. Export =
single `.json`; import **sniffs leading bytes** (`PK\x03\x04` zip vs `{` json) so a future
campaign-pack imports with zero migration (I2a). No migration code pre-1.0 (I5) — keep
`format_version` only.

## 8. Sequencing + slices
**Slice 0 — Package A (`RngService`) [CST-12 → C]:** built FIRST, as its own cluster/plan
(`rng_determinism_design_2026-06-11.md`). Gates the rest. Makes the suspend `rng {map_seed,
history_hash}` real and unblocks the rewind mechanic ([CST-13]). **This is the next execution
step — §2 slices 1–7 follow it.**

Then (firm after Package A lands):
1. **Seam + codec + schema** (headless): `SaveData`/`SaveCodec`/JSON round-trip of roster + rules
   + integrity hash; lossless `InventoryEntry` round-trip (Retry now shares it). New
   `test_save_codec`/`test_save_data`. [CST-1/2/9]
2. **CampaignRules consolidation** — hard-migrate ~70 call sites + delete loose fields + `CampaignData`
   graph loader + node fields (required/excluded/cap, protected_fields, rule mandates/defaults). [CST-3/4/5/6]
3. **Prep screen** (deploy/bench/placement/launch) + New Game→campaign-selector reroute
   (everything-is-a-campaign; last-started/most-recent default). [CST-6]
4. **Save/Load/Continue + slot menu UI** + MainMenu Continue/Load + autosave/manual layout. [CST-10]
5. **Victory/defeat flow rewrite** — `MapResultsScreen` (advance+autosave) + `GameOverScreen` defeat
   menu + rewind hooks; preserve standings renderer for future PvP. [CST-7/12]
6. **Mid-battle suspend** serializer — enemy state + `_unit_states` + activation cursor + watch-set
   + pair-up + rng; idle-FREE/human-driven gate — biggest. [CST-8]
7. **Export/import** (single-json + zip-sniff importer) + story-flip seam + read-only rules view. [CST-11]

Each slice: tests + DoD#1 (GDD_01/07 + GDD_10 status flip) + DoD#2 (check_docs guard where a new
mechanical rule lands, e.g. save `format_version` / schema-key value-set guard).

## 9. Deferred (do-not-forget — `planning_backlog §2b`)
Convoy (D), shop (E), recruit (F), Pair-Up persistence + Support + Rescue (H), campaign-PACK
(I3), the rewind MECHANIC (J / Package A), cross-version migration (I5). Schema reserves
`party.items`/`party.gold` + full-roster persistence so each is later data growth, not a reshape.
**NEW (from CST-7):** a **PvP / scenario mode** reusing the preserved standings-ranking renderer
— a standalone non-campaign match mode (no progression/save advance). Design later; the only
obligation now is to keep the standings renderer extractable, not delete it.
**NEW (from CST-6):** map-data subset/override of a campaign node's placement tiles (node owns
who/how-many; per-node tile override is a later enhancement).
</content>
