---
Type: plan
Status: Target design
Last verified: 2026-07-14
---

# `B4-PREP-DEPLOYMENT` Handoff - Prep Screen - 2026-07-14

Successor to [`b1_cst_slice3_load_picker_handoff_2026-07-14.md`](b1_cst_slice3_load_picker_handoff_2026-07-14.md).
`B1-CST` is **closed** (all three slices Implemented 2026-07-14): a campaign runs
end to end and survives a quit. `B4-PREP-DEPLOYMENT` is the next track, and it
inherits two things that are **already built and waiting for it**. This document
records the seams verified against the code on 2026-07-14 so the next session does
not re-derive them.

## Resume point

- Branch: `agent/claude/save-spine-handoff` (branch from its tip, `072994a`).
- **The v0.4.0 Windows playtest still preempts this work.** As of 2026-07-14 no
  return has landed (there is no `playtest_checklist_v0.4.0_returned_*`). If one
  arrives, pause at a clean commit and run the playtest intake route first;
  live-return repairs belong on the v0.4.0 build branch and must not share a
  commit or branch with prep work.
- **The Load Game picker has never been rendered** - it is covered by headless
  tests only, and it changed the Main Menu's shape (five buttons; each save row is
  three lines). Fold a live look into the next Windows playtest rather than cutting
  a build for it.
- Session note for the picker: `AGENT/Session Notes/2026-07-14i.md`. The shipped
  contracts are `GDD_01_Data_Contracts.md` §CampaignManager Contract and
  `GDD_07_Screens_Panels.md` §Load Game Screen - read those, not the plans.

## Scope

Build the **Prep screen**: the between-map surface where the player picks who
deploys, places them, optionally saves, and begins the battle. The campaign flow
technical plan (§4, `campaign_save_technical_plan_2026-06-21.md`) gives it:

> show required (forced) + roster minus excluded; player deploys up to
> `deployment_cap`, assigns placement onto `player_start_tiles`; manual Save;
> Begin Battle -> GameMap. Benched units gain nothing.

**Two pieces of this track are already built and waiting** (see below): the
node's deployment constraints, and the manual-save seam.

**The prep-hub panel framework (`B3-PHB`) is NOT a prerequisite for a first
slice.** `B3-PHB` is Target design and `B4-CONVOY` is Planned, so shops, trade,
and convoy access cannot land yet. Deploy + place + save + begin does not need
them. Slice accordingly (below) rather than blocking the whole track on `B3-PHB`.

## What already exists (verified against the code 2026-07-14)

Do not rebuild these, and do not change their schema - they were authored *for*
this track.

- **`CampaignNode` already carries all three deployment constraints, authored and
  validated, and NOTHING reads them yet.** `required_units: Array[String]`,
  `excluded_units: Array[String]`, `deployment_cap: int` (-1 = uncapped;
  `CampaignData` validates `-1 or >= 1`). Their comment says it outright:
  "[CST-5] Deployment constraints live on the NODE, not the map. Consumed by
  B4-PREP-DEPLOYMENT; authored and validated here so the prep slice does not force
  a schema change." **Prep is their first consumer.** No schema change is owed.
- **`MapData.player_start_tiles: Array[Vector2i]`** is the placement surface, and
  `GameMap` already centroids it for the opening camera position.
- **`CampaignManager.launch_current_node()` is the "prep -> map" seam**, and says
  so in its own comment ("The prep SCREENS are not this slice; this is the entry
  point they will eventually call"). It resolves the node's map binding, applies
  the roster policy, then `change_scene_to_file(GameMap)`.
- **Every route into a map funnels through that one call**, so prep is inserted in
  ONE place, not three: the campaign "Next" on `GameOverScreen`, and
  `MainMenu._load_campaign_slot` (used by both Continue and the Load Game picker).
- **`CampaignManager.write_campaign_slot(slot_id, save_label)` is built and
  tested** and is exactly the manual-save seam. It returns false when no campaign
  is active (a bare single-map launch has nothing to save) and captures through
  `GameState.capture_campaign_save`. The autosave path (`write_autosave`) already
  uses it.
- **`SaveManager.is_valid_slot_id`** is an allow-list, not a sanitizer, because a
  slot id becomes a filename. **Manual save is the first place a slot id becomes
  player-supplied** - this is where that allow-list finally earns its keep. Reject
  a bad id; never "clean" it.
- **The Load Game picker is the model for the surface**: `LoadGameScreen` is a
  MainMenu overlay on the `ModalScreen` base, and it does not restore a save
  itself - it names a slot and MainMenu runs the restore. Prep's manual-save
  surface should reuse `write_campaign_slot` the same way, rather than growing its
  own capture path.

## The load-bearing change: deployment becomes explicit

Today `GameMap._spawn_units()` **infers** the deployment:

```gdscript
# Player units: roster slot N → player_start_tiles[N]
for i in roster.size():
    if i >= map_data.player_start_tiles.size():
        break
    ...
    _place_and_spawn(u_data, map_data.player_start_tiles[i], "blue")
```

That is roster ORDER, truncated by the number of start tiles, skipping the
incapacitated. It is not a choice - it is a fallback that happens to look like
one. Prep's whole job is to replace it with an **explicit deployment plan** (which
units, on which tiles) that `GameMap` consumes instead of re-deriving.

Recommendation: stage the plan on `GameState` beside the existing launch fields
(`next_map_data_path` / `next_map_roster_policy` / …), and have `_spawn_units`
prefer it when present. **Keep the current inference as the fallback** for the
launch paths that have no prep screen (see landmines) rather than deleting it.

## Recommended slicing

1. **Slice 1 - the deployment plan seam (no UI). IMPLEMENTED 2026-07-14** (see
   `AGENT/Session Notes/2026-07-14j.md`). `GameState.next_map_deployment` carries
   the plan; `GameMap._spawn_units` consumes it and falls back to today's
   roster-order rule when it is absent; `scripts/shared/DeploymentPlan.gd`
   validates it against the party, `player_start_tiles`, and the node constraints.
   Shipped contract: `GDD_01_Data_Contracts.md` §Deployment Plan Contract - read
   that, not this plan.
2. **Slice 2 - the PrepScreen.** A screen (not a modal overlay - it is a
   destination, and `launch_current_node` routes to it) listing the eligible party,
   a deploy toggle per unit, placement onto `player_start_tiles`, and Begin Battle.
   Reroute `launch_current_node` here; that is the one-line change the picker
   handoff promised.

   **Prep has TWO entrances, and that is a design constraint, not a detail.**
   Decided 2026-07-14: a campaign **Retry reroutes to prep** so the player may
   redeploy after a loss, and it covers **both defeat and victory** retries (a
   victory-retry already replays the same node with the result dropped, so there
   is no reason deployment should be frozen for it). One rule: on a campaign map,
   Retry always means "replay this map, and you may redeploy first."

   This works only if the **PrepScreen is a PURE PLAN-AUTHORING SCREEN**: it reads
   the launch `GameState` already has staged (`next_map_data_path` +
   `player_roster`), authors a plan, and hands off to `GameMap`. It must NEVER
   re-apply the roster policy or re-resolve the map binding - all staging stays in
   `launch_current_node`. If prep instead routes *through* `launch_current_node`,
   Retry breaks badly: on a first node that call re-applies `default_roster` and
   reloads the party from disk, throwing away the snapshot-restored one (levels,
   gold, the restored RNG timeline).

   Why Retry is cheap here: `GameOverScreen._on_retry` is already map-scoped and
   does NOT go through `launch_current_node` - it clears the pending result, calls
   `GameState.restore_map_snapshot()`, and reloads the scene. That snapshot restore
   is what makes redeployment coherent: it rolls the party back to map-start state,
   so units that fell during the map are alive again and the eligible list is
   correct. And the Slice 1 plan already survives a Retry, so it is the natural
   pre-selection when prep opens rather than something to rework.
3. **Slice 3 - manual save.** A Save button on prep over `write_campaign_slot`,
   with a player-supplied label and an id the allow-list accepts. Nothing else in
   the game needs to change - the picker already lists whatever gets written.
4. **Later, once `B3-PHB` lands:** convoy/trade/shop panels on prep. Do not
   design them now.

## Landmines

- **The bare single-map launch has no campaign.** `NewGameScreen` still launches a
  map directly through `GameState.configure_next_map`, with no `CampaignManager`
  position - and `write_campaign_slot` returns false for exactly that reason.
  Prep must not appear on that path (and manual save must not offer to save a run
  that does not exist). [CST-6]'s "every map is a 1-node campaign" auto-wrap, which
  would unify these two paths, is **`B6-CAMPAIGN-SHARING`'s**, not this track's -
  do not build it here.
- **Do not persist the deployment plan.** It is chosen at prep and consumed at
  launch; a campaign save is parked *between* maps, so a reload lands back on prep
  and the player deploys again. This mirrors the pending-result decision from Slice
  2/3 (a save mid-results restores parked on the current node) and, like it, keeps
  a reload from committing state for a map that was never played. It also means
  **no new F1 save row** is owed.
- **Panels are an open registry, not an enum.** `AGENTS.md`'s architecture
  principle names prep/on-map activities and panels specifically ([SAC], resolved
  in `registers/shop_activate_configs_open_questions_2026-06-27.md`). If a prep
  service ever needs an engine `match` to add a panel type, the design is wrong.
  This does not bite Slice 1-3 (there are no panels yet), but it constrains Slice 4.
- **Benched units gain nothing** (technical plan §4). Whatever the plan's shape,
  a unit left out of the deployment must not accrue XP, levels, or items.
- **`deployment_cap` is -1 for uncapped, and `CampaignData` rejects 0.** Do not
  treat -1 as "none" or 0 as "uncapped".
- **Permadeath already skips the incapacitated** in `_spawn_units`. Prep must not
  offer a dead unit as deployable - and must not silently drop a *required* unit
  that has died, which is a real campaign state under permadeath. Decide what that
  case does (block launch? warn?) rather than letting it fall through.
- **Additive, as ever.** A launch path with no prep plan must behave exactly as it
  does today.
- **The Retry reroute (Slice 2) has two guards, and both are easy to miss.**
  - **The bare single-map launch has no campaign and no prep**, so Retry there must
    keep `reload_current_scene()` exactly as it does today. Gate the reroute on an
    active campaign or `NewGameScreen`'s Retry dies.
  - **Retry after a SUSPEND RESUME is the nasty one.** A resumed map never takes a
    map-start snapshot (`GameMap` skips `take_map_snapshot` when `is_resuming`), so
    `restore_map_snapshot()` already fails its own validation on that path - and
    `next_map_suspend_payload` is still staged, which means `GameMap` would take the
    suspend spawn path and **ignore the deployment plan entirely**. The player would
    author a deployment that silently does nothing. Either skip the reroute when a
    suspend payload is present, or clear the payload explicitly before routing to
    prep. Decide it; do not let it fall through.

## Tests owed

- `test_game_map_scene`: an explicit plan places the named units on the named
  tiles; an absent plan falls back to today's roster-order rule unchanged.
- A plan validator suite: `deployment_cap` respected (and -1 uncapped);
  `required_units` cannot be benched; `excluded_units` cannot be deployed; a plan
  naming a unit not in the party is rejected; a plan with more units than
  `player_start_tiles` is rejected.
- `test_campaign_manager`: `launch_current_node` routes to prep for a campaign and
  the bare map launch is untouched.
- `test_game_over_sequencing`: a campaign Retry (after defeat AND after victory)
  routes to prep with the party rolled back to map-start state and the previous
  plan pre-selected; a Retry on the bare single-map launch still reloads the map
  directly; a Retry on a suspend-resumed map does not strand the player on a prep
  screen whose plan the suspend spawn path would ignore.
- Prep screen: the eligible list honors required/excluded, Begin Battle is gated
  until the plan is legal, and manual save writes a slot the picker then lists.
- Manual save: a rejected slot id fails loudly and writes nothing (the allow-list's
  first player-supplied test).

## Environment gotchas

- After adding any `class_name` script, run
  `godot --headless --path . --import --quit-after 1000` before the tests, or the
  global class registry will not resolve the new type and every suite referencing
  it fails to parse.
- That import also **generates `.uid` sidecars** - for a new `.tscn`/`.gd` too.
  `check_docs` check 9 fails on any untracked `.uid`, and the pre-commit hook runs
  `check_docs` over the whole working tree, so a stray untracked sidecar blocks an
  unrelated commit. Stage new sidecars with their scene/script.
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

For behavior changes, update the owning `GDD_01`-`GDD_08` contract (prep's surface
contract is `GDD_07_Screens_Panels.md`) and flip the `B4-PREP-DEPLOYMENT` row in
`GDD_10_Roadmap.md` in the same commit (DoD#1). Add a session note and a
newest-first row in `AGENT/Session Notes/INDEX.md` before stopping.

Agents may push only `agent/**` branches. No PR is requested - push the branch
only; human review and merge are manual.
