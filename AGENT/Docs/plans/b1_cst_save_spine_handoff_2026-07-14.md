---
Role: dated
Type: plan
Status: Planned - ready for next-session implementation
Last verified: 2026-07-14
---

# `B1-CST` Save Spine Handoff - 2026-07-14

## Resume point

- Branch: `agent/claude/2026-07-14/save-spine-handoff` (branch from its tip).
- v0.4.0 is built, green, and pushed. Its only open gates are the live Windows
  smoke gate and the reviewer handoff gate, both of which need returned playtest
  evidence. No v0.4.0 code work remains.
- `B1-CST` is the next slice because it is the largest unblocked bottleneck in
  the project: all three of its dependencies (`B1-PKGA`, `B1-F1`,
  `B1-SAVECODEC`) are Implemented, and **eleven still-open tracks depend on it** -
  `B3-CAMPAIGN-RULES`, `B3-PHB`, `B3-CALENDAR-LITE`, `B4-CAMPAIGN-LOOP`,
  `B4-ENCOUNTER-MODEL`, `B4-CONVOY`, `B4-RECRUIT-BASIC`, `B4-PREP-DEPLOYMENT`,
  `B4-PROMOTION-UI`, `B6-CAMPAIGN-SHARING`, and `B6-CAMPAIGN-STATUS`.

Read first:

1. `AGENT/Session Notes/2026-07-14e.md`
2. `AGENT/Docs/plans/campaign_save_technical_plan_2026-06-21.md` (sections 3, 4, 8)
3. `AGENT/Docs/plans/band1_determinism_save_implementation_plan_2026-06-30.md`
   ("Follow-On Slices")
4. `AGENT/Docs/plans/f1_save_schema_manifest_2026-07-06.md` (field ownership)
5. The `B1-CST` row in `AGENT/Docs/plans/project_control_plane_2026-06-29.md`

## What already exists (verified 2026-07-14)

Do not rebuild these:

- `scripts/autoloads/SaveManager.gd` - disk seam and the dedicated suspend JSON
  slot, with the active-map suspend/Continue lifecycle.
- `scripts/save/SaveCodec.gd`, `scripts/save/SaveData.gd` - JSON-safe codec and
  the save envelope; `SaveData` defaults already cover the campaign rule set.
- `scripts/resources/CampaignRules.gd` - `GameState.campaign_rules` is the live
  rule source. Loose `GameState` rule fields are gone and New Game writes into
  `CampaignRules`.

The gap is the campaign layer above them. **`CampaignData` does not exist yet.**

## Slice plan

Take these in order and commit each separately. Stop and record a blocker rather
than widening a slice.

### Slice 1 - `CampaignData` seeding

1. Add a `CampaignData` resource holding the campaign progression graph: node
   ids, node ordering/edges, and each node's map or encounter binding.
2. Seed one real campaign definition from existing map content so the resource
   is exercised by production data, not only a fixture.
3. Load it through `DataManager` using the existing catalogue path. Missing or
   malformed campaign definitions must fail loudly, matching the registry and
   catalogue failure behavior established in v0.4.0.
4. Tests: load, deterministic node ordering, unknown node id, malformed graph,
   and unresolved map/encounter reference.

Honor the resolved decisions - the progression graph is authored data, JSON-
shaped, per [CST-3] and [CST-5]/[CST-6]. Do not reopen them.

### Slice 2 - prep/results flow

> **Slice 1 landed 2026-07-14** (`bad3317`). Slice 2 has its own code-grounded
> handoff: [`b1_cst_slice2_prep_results_flow_handoff_2026-07-14.md`](b1_cst_slice2_prep_results_flow_handoff_2026-07-14.md).
> Read that first - it records the verified seams, including that step 2 below is
> **already satisfied**.

1. Add the campaign entry points named by the technical plan: prep -> map ->
   victory/defeat -> results -> next node.
2. Route victory gold through `ResourceLedger` (v0.4.0 already forbids direct
   `party_gold` writes; documentation check 28 enforces this). **Already done:**
   `TurnManager._apply_victory_rewards` commits a negative `party_gold` `CostSpec`
   through the ledger - do not re-plumb it.
3. Keep roster selection, trade, and deployment UI out of this slice. This slice
   owns the *flow*, not the prep screens - `B4-PREP-DEPLOYMENT` owns those.
4. Tests: node advance on victory, defeat handling, and results state handoff.

### Slice 3 - full campaign saves

1. Persist the campaign envelope: current node, completed nodes, roster, party
   inventory/gold, and the `CampaignRules` selection.
2. Wire Continue/Load against the existing `SaveManager` disk seam. Autosave and
   manual slots per the technical plan section 4.
3. Every new persisted field must be registered in the F1 manifest in the same
   commit. The manifest is the schema owner; an unregistered field is a bug.
4. Tests: campaign save/load round-trip, node-progress restore, and a
   suspend-then-campaign-save interaction check.

## Explicitly deferred

- Turnwheel: [CST-13] is resolved to **hooks-only** in this pass. Build the
  mechanic as a follow-on after charge persistence exists.
- Campaign selector, browser, and export/import UI (`B6-CAMPAIGN-SHARING`).
- Prep deployment screens, convoy, and shop (`B4-PREP-DEPLOYMENT`, `B4-CONVOY`,
  `B4-SHOP-ECONOMY`).
- The `BattleMapDef`/`BattleEncounterDef` split (`B4-ENCOUNTER-MODEL` Slice 2);
  bind campaign nodes against the current map id and let the split adapt later.

## Playtest-return preemption

The v0.4.0 Windows playtest is still external and **takes priority**. If evidence
arrives, pause save-spine work at a clean commit and run the playtest intake
route first.

The save spine was chosen partly because it does not collide with a playtest
return: the return will land on the UI, input, and display surfaces, while this
work sits in the campaign/save layer. Even so, **do not mix live-return repairs
and save-spine work in one commit.** Triage repairs belong on the v0.4.0 build
branch, not here.

## Verification and commit discipline

Before each code commit:

```bash
bash scripts/check_env.sh
python3 AGENT/Docs/check_docs.py
bash scripts/ci/check_rng_usage.sh
bash run_tests.sh
```

For behavior changes, update the owning `GDD_01`-`GDD_08` contract and the
`B1-CST` control-plane row in the same commit. Add a session note and a
newest-first row in `AGENT/Session Notes/INDEX.md` before stopping.

## Known operational state

- Agents may push only `agent/**` branches. `v0.3.0-features` is owner-owned and
  off-limits; its MenuScale fix (`f676fa5`) is already carried by every agent
  branch, so nothing is stranded there.
- No PR is requested. Push the branch only; human review and merge are manual.
- `repos.yaml` still sets `active_branch` to `v0.3.0-features` for this repo.
  That is deliberate and unchanged - it should be retargeted only once the
  v0.4.0 gates close.
- Windows-host Godot remains the visual source of truth; container verification
  is headless.
