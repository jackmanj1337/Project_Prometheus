---
Role: dated
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-02
---

# Band 4 Campaign Loop Implementation Plan

**Started:** 2026-07-02 (closing audit finding C2 of
[`band_plans_audit_2026-07-02.md`](../../Code%20Reviews/band_plans_audit_2026-07-02.md);
the thin integration plan owed by handoff decision `D1`).

**Track ID:** `B4-CAMPAIGN-LOOP`

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 4 rows. Drafted from
[`band4_implementation_plan_handoff_2026-06-30.md`](band4_implementation_plan_handoff_2026-06-30.md)
decisions `D1`/`D2`.

## Purpose

Prove the Band 4 exit check end to end: **one short campaign loop can move
map -> victory/defeat -> prep -> next map with save/suspend coverage.** This is
the *integration* plan (`D1`): it wires together what the Band 1-3 plans and
the four Band 4 sub-plans build, and it finalizes the minimum-loop content that
handoff decision `D2` deferred here. It does not restate any other plan's
slices.

## Minimum Loop Content (Finalizes `D2`)

The first loop proof uses the smallest content that exercises every seam:

- A **three-node fixture campaign**: `battle -> hub -> battle`.
  - Battle nodes use the **existing deploy-only prep** (`prep_panels: []`) and
    Begin Battle (`PHB-4`).
  - The hub node advances via Continue (`PHB-4/5`) and exists to prove the
    non-battle node path.
- **Victory** applies rewards through the ledger/reward paths that exist by
  then and advances progression to the next node.
- **Defeat** reaches the defeat flow and offers Retry / Load without corrupting
  campaign state.
- **Save/suspend coverage:** autosave on node entry, manual save in prep,
  suspend mid-map, and Continue/Load resuming each of those points.

Per `D2`, **convoy and shop are not in the first loop proof** — they are close
fast-follows (convoy first, shop after convoy) that attach to the hub/prep
nodes of the same fixture campaign (Slice 4). Dialogue, recruit, villages,
doors/chests, and difficulty/death-mode selection are not in this plan's loop;
they join the loop through their own grouped plans (handoff `D5`).

## Non-Goals

- Do not build campaign/save systems here. `B1-CST` owns `CampaignData`,
  SaveManager file I/O, Continue/Load, autosave/manual slots, and the
  victory/defeat screens; this plan *consumes* them.
- Do not build prep panels, convoy, shop, recruit, or dialogue here. Each is
  its own plan; this plan only flips them on in the fixture campaign once they
  exist.
- Do not build campaign selection/import/export UI beyond what `B1-CST`
  provides. Campaign sharing is `B6-CAMPAIGN-SHARING`.
- Do not add saved state. Every field this loop touches must already have its
  F1 row via `B1-F1` / `B1-CST` (campaign progression, map progression, prep
  state, suspend state).
- Do not tune content balance. The fixture maps are seams-proof content, not
  the v1 demo campaign (that is `CONTENT-V1`).

## Source Docs

- [`band4_implementation_plan_handoff_2026-06-30.md`](band4_implementation_plan_handoff_2026-06-30.md)
  (`D1`, `D2`, `D5`)
- [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
- [`band1_determinism_save_implementation_plan_2026-06-30.md`](band1_determinism_save_implementation_plan_2026-06-30.md)
  (the `B1-CST` spine and follow-on slices)
- [`campaign_save_technical_plan_2026-06-21.md`](campaign_save_technical_plan_2026-06-21.md)
- [`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](band3_core_authoring_foundations_implementation_plan_2026-06-30.md)
  (Slice 9, `B3-PHB`)
- [`band4_convoy_implementation_plan_2026-06-30.md`](band4_convoy_implementation_plan_2026-06-30.md)
  and
  [`band4_shop_economy_implementation_plan_2026-06-30.md`](band4_shop_economy_implementation_plan_2026-06-30.md)
  (fast-follow attach points)
- [`planned_unimplemented_feature_triage_2026-06-28.md`](planned_unimplemented_feature_triage_2026-06-28.md)

## Decisions Not To Reopen

- `D1`: this is a thin integration plan referencing the other plans.
- `D2`: the first loop proof excludes convoy/shop; convoy is the first
  fast-follow, shop follows convoy.
- `PHB-1..7`: node types, opt-in `prep_panels`, free navigation, immediate
  transaction commit, no hub-suspend snapshot.
- `[CST-8]`: suspend is between committed actions for human-controlled
  factions.
- F1 owns saved-field rows; this plan adds none.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates before the first slice:

- `B1-CST` campaign spine complete: `CampaignData` graph, SaveManager file
  I/O, prep deployment flow, victory/defeat screens, Continue/Load,
  autosave/manual slots.
- `B1-SUSPEND` for the mid-map suspend leg of Slice 3 (Slices 1-2 can land
  before it; the suspend assertions join when it exists).
- `B3-PHB` for `node_type`/`prep_panels`/Continue semantics.
- `B4-CONVOY` / `B4-SHOP-ECONOMY` only for Slice 4 fast-follow attachment.

This track's control-plane dependency row lists `B4-CONVOY`,
`B4-SHOP-ECONOMY`, and `B4-RECRUIT-BASIC` because the *finished* loop includes
them; per `D2` they gate Slice 4+ attachments, **not** the Slice 1-3 proof.

## Slice 0 - Preflight After Gates

**Goal:** confirm the loop has nothing left to invent.

Implementation checklist:

- Confirm every Minimum Loop Content behavior above exists behind its owning
  plan's tests (`B1-CST` suites, `test_prep_hub.gd`).
- Confirm F1 rows: campaign progression cursor, per-map completion state, prep
  state, suspend state, autosave/manual slot metadata.
- Run `rg -n "CampaignData|node_type|prep_panels|autosave|suspend|Continue" scripts`
  and re-verify the touchpoints this plan assumes.

Tests: none in preflight.

## Slice 1 - Fixture Campaign And Victory Progression

**Goal:** map -> victory -> prep -> next map, on the fixture campaign.

Files to create or touch:

- fixture campaign data under the project-standard campaign content path
  (three nodes: `battle -> hub -> battle`, deploy-only prep)
- `scripts/tests/test_campaign_loop.gd` (new)

Implementation steps:

1. Author the three-node fixture campaign with two small seams-proof maps.
2. Wire nothing new: node advance, rewards, and prep entry must already flow
   through `B1-CST` + `B3-PHB` code paths.
3. Any gap discovered here is a defect in the owning plan's slice — fix it
   there (and note it on that plan's control-plane row), not with loop-local
   patches.

Tests:

- `test_campaign_loop.gd`: scripted victory on map 1 advances to the hub;
  Continue advances to map 2; rewards land where the owning systems put them.
- Progression cursor round-trips through save/load at each node boundary.

## Slice 2 - Defeat And Retry/Load

**Goal:** losing does not strand or corrupt the campaign.

Implementation steps:

1. Script a defeat on map 1; assert the defeat flow offers Retry / Load.
2. Retry restores the map-start state (including RNG per `B1-PKGA` Step 2).
3. Load returns to the last autosave/manual save; campaign progression is
   unchanged by the defeat.

Tests:

- Extend `test_campaign_loop.gd` with the defeat -> Retry and defeat -> Load
  legs; assert no progression advance and no state corruption.

## Slice 3 - Save/Suspend/Continue Coverage

**Goal:** every leave-and-return point of the loop survives a restart.

Implementation steps:

1. Assert autosave exists on node entry and manual save works in prep.
2. Suspend mid-map (between committed actions, `[CST-8]`), relaunch, Continue:
   turn/phase, unit states, and RNG timeline resume exactly (needs
   `B1-SUSPEND`).
3. Completing the map after resume clears the suspend record
   (`test_map_runtime_resets_on_completion` fixture family from the F1
   manifest).

Tests:

- Extend `test_campaign_loop.gd` (or a focused `test_campaign_suspend.gd`)
  with the three resume legs: from autosave, from manual prep save, from
  mid-map suspend.

## Slice 4 - Fast-Follow Attachments (Convoy, Then Shop)

**Goal:** attach the `D2` fast-follows to the same fixture without changing the
loop proof.

Implementation steps:

1. When `B4-CONVOY` lands: add the convoy panel to the hub/prep node
   (`prep_panels: ["convoy"]`) and re-run the full loop suite.
2. When `B4-SHOP-ECONOMY` lands: add a prep shop panel the same way.
3. Each attachment re-runs Slices 1-3 assertions unchanged — the loop proof
   must not depend on which panels are enabled.

Tests:

- Loop suite green with panels off, with convoy on, and with convoy+shop on.
- One transaction per panel survives a save/reload (re-derived from party
  state, `PHB-7`).

## Slice 5 - Manual Playtest Checklist

**Goal:** a human runs the loop once per the project playtest pattern.

Implementation checklist:

- Write a short loop-focused handbook under `AGENT/Docs/playtests/` (victory
  leg, defeat leg, each resume leg, panels if attached).
- Triage results through the standard playtest flow before flipping the
  `B4-CAMPAIGN-LOOP` row to validated.

## Implementation Commit Order

1. Slice 1 fixture + victory progression test.
2. Slice 2 defeat legs.
3. Slice 3 save/suspend/continue legs.
4. Slice 4 attachments (one commit per attached panel).
5. Slice 5 checklist + playtest triage.

DoD#1: the loop proof is behavior-integrating, not behavior-changing; GDD
updates belong to the owning feature plans. Flip `GDD_10` / control-plane
status for `B4-CAMPAIGN-LOOP` when Slice 3 lands, in the same commit.

## Verification Checklist

Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
git diff --check
```
