---
Role: dated
Type: plan
Status: Implemented 2026-07-14
Last verified: 2026-07-14
---

# `B1-CST` Slice 2 Handoff - Prep / Results Flow - 2026-07-14

> **Implemented 2026-07-14.** `CampaignManager` (`scripts/autoloads/CampaignManager.gd`)
> owns the campaign runtime position and the flow; `DataManager.get_map_registry_entry`
> closed the map-lookup gap; `GameOverScreen` gained the campaign "Next" route.
> Covered by `scripts/tests/test_campaign_manager.gd`. The contract now lives in
> `GDD_01_Data_Contracts.md` §CampaignManager Contract - read that, not this plan.
>
> **One deviation from the "Recommended shape" below:** victory does NOT advance
> the node. It records a pending result, and the position advances only when the
> results surface commits it - the only shape that satisfies the retry landmine,
> since Retry replays the same map. See the contract for the reasoning.
>
> Next: **Slice 3** (campaign saves) registers `campaign.campaign_id` /
> `campaign.node_id` / `campaign.cleared_nodes[]` in the F1 manifest and adds the
> serializer.

Successor to [`b1_cst_save_spine_handoff_2026-07-14.md`](b1_cst_save_spine_handoff_2026-07-14.md),
which remains the parent plan. That document's Slice 2 section is the contract;
this one records the code seams verified on 2026-07-14 so the next session does
not re-derive them.

## Resume point

- Branch: `agent/claude/2026-07-14/save-spine-handoff` (branch from its tip).
- **Slice 1 is Implemented** (`bad3317`): `CampaignData`/`CampaignNode` hold the
  authored JSON progression graph, `DataManager` loads `data/campaigns/` in the
  catalogue pass with loud structural + map-reference validation, and
  `proving_grounds` seeds a five-node campaign over the shipped objective maps.
  Session note: `AGENT/Session Notes/2026-07-14f.md`.
- **The v0.4.0 Windows playtest still preempts this work.** As of 2026-07-14 no
  return has landed (there is no `playtest_checklist_v0.4.0_returned_*`). If one
  arrives, pause at a clean commit and run the playtest intake route first;
  live-return repairs belong on the v0.4.0 build branch and must not share a
  commit or branch with save-spine work.

## Slice 2 scope (from the parent plan)

Own the **flow**: prep -> map -> victory/defeat -> results -> next node.

Explicitly NOT this slice: roster selection, trade, and deployment screens
(`B4-PREP-DEPLOYMENT`), convoy/shop, the campaign selector and browser
(`B6-CAMPAIGN-SHARING`), and persistence (Slice 3).

Tests owed: node advance on victory, defeat handling, and results state handoff.

## What already exists (verified against the code 2026-07-14)

Do not rebuild these.

- **Victory gold already routes through `ResourceLedger`.**
  `TurnManager._apply_victory_rewards` commits a negative `party_gold` `CostSpec`
  through the ledger and appends `MapData.reward_items` to `GameState.party_items`.
  The parent plan's "route victory gold through ResourceLedger" requirement is
  therefore **already satisfied** - do not re-plumb it. Documentation check 28
  still forbids direct `party_gold` writes.
- **Map resolution already emits everything the flow needs.** `TurnManager` emits
  `EventBus.map_victory` / `EventBus.map_defeat`, then
  `EventBus.map_resolved(winner_group: String, standings: Array)` carrying the
  full per-group ranked standings. A first-result latch already prevents a
  double fire.
- **`GameOverScreen` already consumes all three** and renders the ranked
  standings. It holds presentation until the level-up/promotion queue drains
  (V026-05d), deletes the suspend slot on resolution
  (`_delete_suspend_after_resolution`), and offers Retry
  (`GameState.restore_map_snapshot` + scene reload) and Quit
  (`GameState.reset_map_state` -> `Boot.tscn`).
- **The map launch seam is `GameState.configure_next_map(map_path,
  roster_policy, roster_source)`** followed by
  `change_scene_to_file("res://scenes/core/GameMap.tscn")`. `NewGameScreen._on_start`
  is the working example.
- `GameState` carries `player_roster`, `party_gold`, `party_items`, and
  `campaign_rules` (the live rule source).

## The actual gap

`GameState` has **no campaign position**: there is no active campaign id, current
node id, or cleared-node set anywhere in the runtime, and nothing advances a node
on victory. Slice 1 built the graph; nothing walks it.

Also missing: a **map-registry entry lookup by id**. `CampaignNode.map_id` binds
to a `map_registry` id, but the only id-aware helper today is
`DataManager.collect_map_registry_ids` (validation only, returns a presence set),
and `NewGameScreen` reads `map_registry.json` from disk itself
(`_MAP_REGISTRY_PATH`, plus a hardcoded `_FALLBACK_MAP_OPTIONS`). The campaign
flow needs the full entry (`map_data_path`, `roster_policy`, `roster_source`).

## Recommended shape

1. **Add a registry entry accessor to `DataManager`** - e.g. cache the parsed
   map registry at load and expose `get_map_registry_entry(map_id) -> Dictionary`
   / `has_map_registry_entry(map_id)`. Resolve through this rather than adding a
   second disk read; leave `NewGameScreen`'s existing path alone unless the
   accessor cleanly replaces it.
2. **Add a `CampaignManager` autoload** (`scripts/autoloads/CampaignManager.gd`),
   registered in `project.godot` **after `DataManager`** (it depends on the
   campaign catalogue at `_ready`). It owns the campaign runtime position:
   - state: `active_campaign_id`, `current_node_id`, `cleared_node_ids`
   - `start_campaign(campaign_id) -> bool` - resolves the `CampaignData`, seeds
     the position at `start_node_id`. Unknown id fails loud.
   - `launch_current_node()` - resolves `node.map_id` through the registry
     accessor, then drives `GameState.configure_next_map` + the roster policy and
     changes scene to `GameMap.tscn`. This is the "prep -> map" entry point; the
     prep *screens* stay with `B4-PREP-DEPLOYMENT`.
   - `complete_current_node()` - marks the node cleared and advances to its
     successor. A terminal node (`CampaignNode.is_terminal()`) ends the campaign.
   - `is_campaign_complete()`.
3. **Wire the transitions off the existing EventBus signals.** Victory ->
   mark cleared + advance + build the results payload. Defeat -> no advance, no
   clear; the campaign stays parked on the current node.
4. **Results state handoff**: expose a results payload (campaign id, completed
   node id, next node id or campaign-complete, `winner_group`, `standings`) that
   the results surface reads. `GameOverScreen` already receives `winner_group`
   and `standings` from `map_resolved`; give it a "Next" route when a campaign is
   active. A dedicated `MapResultsScreen` is the technical plan's eventual target
   (§4, and the standings renderer is meant to stay reusable for a future PvP
   scenario mode) - if a full screen widens the slice, hand the state off and
   record the screen as a follow-on rather than building prep UI here.

## Landmines

- **Retry must not double-award or advance.** `GameOverScreen._on_retry` restores
  the map snapshot and reloads the scene. Rewards are applied by `TurnManager` on
  victory; a node advance must not survive a retry of the same map. Test this.
- **Do not break the single-map launch.** `NewGameScreen` launches a bare map
  today (including `is_dev_only` test maps) with no campaign attached. Campaign
  flow is additive: a null/unset campaign must behave exactly as it does now.
  `[CST-6]`'s "every map is a 1-node campaign" auto-wrap belongs with the
  campaign selector and is **deferred**.
- **Persist nothing in this slice.** The campaign position is runtime-only until
  Slice 3. The F1 manifest already reserves `campaign.campaign_id`,
  `campaign.node_id`, and `campaign.cleared_nodes[]`; Slice 3 registers them and
  adds the serializer. An unregistered persisted field is a bug.
- **Node bindings stay `map_id`-only.** `B4-ENCOUNTER-MODEL` splits map/encounter
  later; `[CNC-3]` asked for exactly today's adapter-friendly shape.

## Environment gotchas (hit during Slice 1)

- After adding any `class_name` script, run
  `godot --headless --path . --import --quit-after 1000` before the tests, or the
  global class registry will not resolve the new type and every suite referencing
  it fails to parse.
- That import also **generates `.uid` sidecars**. `check_docs` check 9 fails on
  any untracked `.uid`, and the pre-commit hook runs `check_docs` over the whole
  working tree - so a stray untracked sidecar blocks an unrelated commit. Stage
  new sidecars with their script.
- Commit attribution: `repo/AGENTS.md` forbids `Co-authored-by` model trailers.
  Use `AI-Tool` / `AI-Model` / `AI-Run-ID` / `AI-Workspace` trailers and keep the
  human as git author.

## Verification and commit discipline

Before each code commit:

```bash
bash scripts/check_env.sh
python3 AGENT/Docs/check_docs.py
bash scripts/ci/check_rng_usage.sh
bash run_tests.sh
```

For behavior changes, update the owning `GDD_01`-`GDD_08` contract and the
`B1-CST` control-plane row in the same commit (DoD#1), and flip the Slice 2 row
in `GDD_10_Roadmap.md`'s Next Work Queue. Add a session note and a newest-first
row in `AGENT/Session Notes/INDEX.md` before stopping.

Agents may push only `agent/**` branches. No PR is requested - push the branch
only; human review and merge are manual.
