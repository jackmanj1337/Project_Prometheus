# Campaign-Rules Contract + Between-Map Save/Load — Implementation Plan

**Status:** Planned (approved 2026-06-15; implementation deferred)
**Last verified:** 2026-06-15
**Authority:** GDD_01 §CampaignRules Contract; GDD_10 §Phase 3 Systems
**See also:** `campaign_rules.md`, `campaign_rules_firming_notes_2026-05-25.md`

## Context

This is the **keystone** of the deferred 1.0-campaign cluster. Today the per-save
gameplay rules live as **loose fields on `GameState`** (`permadeath_enabled`,
`leveling_method`, `auto_promote_at_max_level`, `pair_up_enabled`, `max_skills`,
`max_inventory`), and there is **no on-disk save** — the only persistence is an
in-memory Retry snapshot (`GameState._map_start_snapshot`). Downstream features are
blocked on this: the pre-battle deployment screen, shop, recruit mechanic, and the
pair-up/support/rescue *ownership* model all depend on a real campaign-rules contract
and a between-map save.

This plan delivers two things:
1. **Consolidate** the loose rules into the existing `CampaignRules` resource as the
   single per-save rule object on `GameState`, add the GDD target-design fields, and
   rewire every reader + New Game.
2. **Between-map (campaign) save/load**: a versioned on-disk save holding the
   persistent layer (roster, economy, rules, progress) with a Continue flow.

### Decisions taken (with the user, 2026-06-15)
- Scope = contract consolidation **+ between-map save/load**; **mid-battle suspend
  save is deferred** (it needs M14 activation-scheduler serialization + live enemy
  state, and the roadmap rides it with M15 Part B).
- Save format = **plain Dictionaries → JSON with an explicit `save_version`** field
  (mirrors the existing `_snapshot_unit_data` Dictionary shape; migration-friendly).
- Per-rule **adjustable/locked** model is **specified in the contract but not
  enforced yet** — `CampaignRules` stays a flat value object; New Game keeps today's
  all-adjustable behavior. The lock metadata lands with campaign authoring later.

### Adopted firming-note defaults (not re-litigated)
Rules chosen at New Game and stable for the life of the save (migration only); rule
flags stored explicitly, never inferred; Pair Up pairings persist (already
snapshotted); Support/Rescue state is **versioned separately** and out of scope until
those systems exist; Pair Up and Rescue are mutually exclusive by default.

## Key findings from exploration

- **`CampaignRules` already exists as a stub** (`scripts/resources/CampaignRules.gd`,
  `class_name CampaignRules extends Resource`) with all six live fields + the
  target-design fields (`exp_gaining_factions`, etc.) and a `make_default()`. It is
  **not yet referenced** — fields are still loose on `GameState`.
- **Reader surface is small and bounded** (the whole consolidation):
  `scripts/autoloads/PairUpRegistry.gd:84` (`pair_up_enabled`),
  `scripts/ui/ActionMenu.gd:108` (`pair_up_enabled`),
  `scripts/units/Unit.gd` (`permadeath_enabled:458`, `auto_promote_at_max_level:731`,
  `leveling_method:785`, `max_skills:1047`),
  `scripts/ui/NewGameScreen.gd` (sets all four, lines 100–128). `max_inventory` and
  `exp_gaining_factions` have **no readers yet** (future-facing).
- **An on-disk save model already half-exists in-memory.** `GameState`
  `take_map_snapshot` / `restore_map_snapshot` + `_snapshot_unit_data` /
  `_restore_unit_data` (line ~500) already serialize a `UnitData` to a Dictionary and
  back, plus `_snapshot_party_gold` / `_snapshot_party_items` and the
  `PairUpRegistry.serialize()/restore()` round-trip. **Reuse `_snapshot_unit_data` as
  the disk roster serializer** rather than writing a new one.
- The persistent layer is already identified on `GameState`: `player_roster:
  Array[UnitData]`, `party_gold`, `party_items`, plus launch-routing
  (`next_map_data_path` etc., which is launch state, not rules).
- `GameState` line 4 has a standing `TODO save-system` noting the snapshot is
  in-memory only and what suspend-save additionally needs — confirms suspend save is
  the deferred superset.

---

## Part A — CampaignRules consolidation (the contract)

Make `CampaignRules` the live per-save rule object; keep the change behavior-neutral.

1. **`GameState` owns a `campaign_rules: CampaignRules`** (default
   `CampaignRules.make_default()`). Replace the six loose fields with thin
   pass-through accessors (`is_permadeath()`, etc.) and update the ~6 reader sites to
   call them — the surface is small enough that a clean cutover beats a compatibility
   shim.
2. **Rewire readers** (the bounded list above) to read through `campaign_rules`:
   `Unit.gd`, `PairUpRegistry.gd`, `ActionMenu.gd`.
3. **New Game writes into `campaign_rules`** (`NewGameScreen._persist_rules` / `open`)
   instead of loose `gs.set(...)`.
4. **Wire the one cheap, unblocking target field:** `exp_gaining_factions` consumed by
   `CombatResolver` EXP gating (GDD_02 §EXP). Leave the rewind-charge pool and
   follow-up-threshold override as documented fields only (owned by the determinism
   contract; no consumer in this pass).
5. **Reset semantics:** a New Game resets `campaign_rules` to defaults;
   `reset_map_state()` must NOT touch `campaign_rules` (it's save-level, not map-level).

## Part B — Between-map campaign save/load

A new **`SaveManager` autoload** (`scripts/autoloads/SaveManager.gd`) owning the
on-disk campaign save. `GameState` stays the live runtime; `SaveManager`
serializes/deserializes it.

1. **Save schema (a single Dictionary → JSON at `user://saves/<slot>.json`):**
   ```
   {
     "save_version": 1,
     "campaign_id": "<id>",            # which campaign/content set
     "progress": { "chapter_index": int, "next_map_data_path": String,
                   "completed_maps": [String] },   # minimal LINEAR model
     "campaign_rules": { ...CampaignRules.to_dict() },
     "roster": [ _snapshot_unit_data(u) ... ],      # reuse existing serializer
     "economy": { "gold": int, "items": [String] },
     "pair_up": PairUpRegistry.serialize(),
     "support": { "version": 1 }       # reserved, versioned separately, empty now
   }
   ```
   `support` is a reserved, separately-versioned sub-block so the Support system can
   evolve without bumping the whole `save_version`.
2. **`CampaignRules.to_dict()` / `static from_dict(d)`** — explicit field-by-field
   (do NOT use `ResourceSaver`), defaulting any missing key from `make_default()` so
   old saves load forward.
3. **`SaveManager` API:** `save_campaign(slot)`, `load_campaign(slot) -> bool`,
   `has_save(slot)`, `list_saves()`, `delete_save(slot)`. `load_campaign` populates
   `GameState.campaign_rules`, `player_roster`, economy, progress, and the pair-up
   registry (reuse `_restore_unit_data` + `reg.restore`).
4. **Migration:** a `_migrate(dict)` step keyed on `save_version` (no-op at v1; the
   hook + version check exist so v2 has a home). Unknown/garbled save → return false,
   surface a non-destructive error (never overwrite a save on a failed load).
5. **Progress model (minimal, linear):** `chapter_index` + `next_map_data_path` +
   `completed_maps`. "Continue" loads the slot and routes to `next_map_data_path` via
   the existing `configure_next_map`. Branching/chapter-graph is explicitly out of
   scope (single linear campaign), noted as a future extension.
6. **Save/Continue trigger points (wiring only, minimal UI):**
   - Auto-save (or an explicit Save) on map victory, after rewards are granted and
     `configure_next_map` sets the next map.
   - Main menu **Continue** button → `SaveManager.load_campaign(default_slot)` →
     route to `next_map_data_path`. New Game still starts fresh and writes slot 0.
   - Full multi-slot save/load UI is deferred; this pass wires one default slot.

## What this unblocks (and explicitly does NOT build)
- **Unblocks:** deployment/shop/recruit (they now have a persistent roster/economy +
  a rules object to read), and the pair-up/support/rescue ownership questions (rules
  + reserved support block have a home).
- **Out of scope:** mid-battle suspend save; multi-slot save UI; branching campaign
  structure; the deployment/shop/recruit screens themselves; Support & Rescue systems;
  enforcing the adjustable/locked rule model.

## Tests (headless, glob-discovered `scripts/tests/test_*.gd`)
- **`test_campaign_rules.gd`** (new): `make_default()` values; `to_dict` →
  `from_dict` round-trip equality; `from_dict` of a partial dict fills missing keys
  from defaults (forward-compat).
- **`test_save_manager.gd`** (new): full save→load round-trip restores rules, roster
  (HP/inventory/modifiers via the existing `_snapshot_unit_data` fields), economy, and
  pair-up registry; `save_version` mismatch routes through `_migrate`; a
  corrupt/missing file makes `load_campaign` return false without mutating live
  `GameState`. Use an isolated `user://` (the suite already gives each worker its own
  HOME — see `run_tests.sh`), mirroring `test_settings_manager`.
- **Extend `test_game_state.gd`**: rule reads go through `campaign_rules`;
  `reset_map_state()` leaves `campaign_rules` untouched; a New Game resets them.
- Behavior-neutral guard: existing `Unit` / `PairUpRegistry` / `ActionMenu` /
  promotion / leveling tests must stay green after the reader rewire.

## Documentation (DoD#1 — same commits)
- GDD_01 §CampaignRules Contract: move the consolidation + `exp_gaining_factions` from
  **Target design** to **Implemented**; add the save-schema + `save_version` contract.
- `campaign_rules.md`: update "Current GameState fields" → the `campaign_rules`
  object; record the save schema and the linear progress model.
- `campaign_rules_firming_notes_2026-05-25.md`: mark the questions this plan answers
  as resolved (rules-at-New-Game, persistence per rule, format, migration), per the
  note's own §Follow-up; leave Support/Rescue specifics open.
- GDD_10 §Phase 3 Systems: flip "Firm up the campaign-rules contract" + "Between-map
  save/load" to Implemented (between-map only); note suspend-save still deferred.
- DoD#2: if a checkable rule is ratified (e.g. "every `CampaignRules` field appears in
  `to_dict`/`from_dict`"), add it to `check_docs.py`; otherwise note none. Bump
  `Last verified` on every edited GDD file (check 6).

## Suggested commit sequence
1. Part A: `GameState.campaign_rules` + accessors + reader rewire + New Game; tests;
   GDD_01/campaign_rules.md DoD#1. (Behavior-neutral — full suite green.)
2. `exp_gaining_factions` wired into `CombatResolver` EXP gating + test + GDD_02/GDD_01.
3. Part B: `CampaignRules.to_dict/from_dict` + `SaveManager` + schema/migration; tests.
4. Save/Continue wiring (victory auto-save + Main Menu Continue) + GDD_10/GDD_07 DoD#1.
5. Session note + INDEX row.

## Verification (end-to-end)
- Headless: `bash run_tests.sh` green incl. the two new suites; `python3
  AGENT/Docs/check_docs.py` 12/12.
- Live run: New Game with non-default rules → win map 1 → save written; relaunch →
  **Continue** restores the same roster/gold/rules and routes to the next map. Inspect
  `user://saves/0.json` for the expected schema. Confirm a hand-corrupted save fails
  gracefully (Continue disabled / error, no crash, no overwrite).
