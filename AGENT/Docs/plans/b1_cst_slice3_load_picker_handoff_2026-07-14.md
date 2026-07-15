---
Type: plan
Status: Implemented
Last verified: 2026-07-14
---

# `B1-CST` Slice 3 Handoff - Load Game Picker - 2026-07-14

> **Implemented 2026-07-14** (`4d96b1a`) - the picker landed and `B1-CST` Slice 3
> is closed. The shipped surface contract is
> [GDD_07 - Screens And Panels](../../GDD/GDD_07_Screens_Panels.md) §Load Game
> Screen; read that, not this plan, for how the picker behaves. One deviation from
> the Recommended shape below: the picker does **not** call
> `MainMenu._load_campaign_slot` directly - it emits `slot_load_requested` and
> MainMenu runs the restore, which keeps Continue and Load Game on one path and
> leaves the eventual prep reroute a one-line change. Manual save remains
> unbuilt and remains `B4-PREP-DEPLOYMENT`'s.

Successor to [`b1_cst_slice2_prep_results_flow_handoff_2026-07-14.md`](b1_cst_slice2_prep_results_flow_handoff_2026-07-14.md);
[`b1_cst_save_spine_handoff_2026-07-14.md`](b1_cst_save_spine_handoff_2026-07-14.md)
remains the parent plan. Slice 3's **save spine is Implemented** (`b8a2125`,
2026-07-14) - this document covers the **only thing left in Slice 3**: the Load
Game picker. It records the seams verified on 2026-07-14 so the next session does
not re-derive them.

## Resume point

- Branch: `agent/claude/2026-07-14/save-spine-handoff` (branch from its tip).
- **The v0.4.0 Windows playtest still preempts this work.** As of 2026-07-14 no
  return has landed (there is no `playtest_checklist_v0.4.0_returned_*`). If one
  arrives, pause at a clean commit and run the playtest intake route first;
  live-return repairs belong on the v0.4.0 build branch and must not share a
  commit or branch with save-spine work.
- Session note for the spine: `AGENT/Session Notes/2026-07-14h.md`. The contract
  is `GDD_01_Data_Contracts.md` §CampaignManager Contract - read that, not this
  plan, for how the campaign envelope behaves.

## Scope

Build the **Load Game picker**: a MainMenu overlay listing the written campaign
slots, loading the chosen one, and deleting a slot. That is all of Slice 3 that
remains.

**Manual save is NOT in this slice** (reassigned 2026-07-14). A manual campaign
slot is a **between-map** action, and prep is the only between-map screen the
technical plan (§4) gives it; mid-map saving is already the suspend save's job.
The manual-save surface therefore belongs to **`B4-PREP-DEPLOYMENT`**.
`CampaignManager.write_campaign_slot(slot_id, label)` is built and tested and is
waiting for that screen - do not invent a home for it here.

When the picker lands, flip the `B1-CST` Slice 3 row in `GDD_10_Roadmap.md` from
**Split** to **Implemented** in the same commit (DoD#1).

## What already exists (verified against the code 2026-07-14)

Do not rebuild these. The entire disk seam the picker needs is built and covered
by `scripts/tests/test_save_manager.gd` (21/21).

- **`SaveManager.list_slots() -> Array[Dictionary]`** returns the picker's rows,
  **newest first**. Each row: `slot_id`, `label`, `header`, `saved_at_unix`,
  `path`, `write_seq`. The `header` is mirrored out of the save document at write
  time (`header.campaign_id`, `header.node_id`, `header.party {count, gold, lord}`),
  **so the picker can render every row without opening and validating each save
  file**. Use it; do not load N saves to draw a list.
- **A row whose file has vanished is already skipped by `list_slots`.** The picker
  can never be handed a row it cannot load.
- **Rows order by a monotonic `write_seq`, not the timestamp.** `saved_at_unix` is
  whole-second resolution, so two saves written in the same second tie. Render the
  timestamp; do not re-sort by it.
- **`SaveManager.load_slot(slot_id) -> SaveData`** (null on unparseable/invalid),
  **`has_slot`**, **`delete_slot`** (removes the file, its index row, and clears
  the Continue pointer if it pointed there).
- **`SaveManager.AUTOSAVE_SLOT`** is the reserved id the campaign flow writes on
  every node commit. It is a normal row in `list_slots` - the picker should mark
  it as the autosave rather than hiding it.
- **The load route already exists and is tested**: `MainMenu._load_campaign_slot(save_manager, slot_id)`
  restores through `GameState.configure_campaign_resume` and then launches the
  parked node via `CampaignManager.launch_current_node()`. It already reports a
  completed campaign instead of failing into an empty launch. **The picker should
  call this, not re-implement the restore.**
- **`SaveManager.get_continue_target()`** is what MainMenu's Continue routes on
  (`{kind: "suspend"|"slot", slot_id}`). The picker does not need to touch it -
  `delete_slot` already keeps it honest.

## Recommended shape

1. **`scenes/ui/LoadGameScreen.tscn` + `scripts/ui/LoadGameScreen.gd`**, following
   the established overlay pattern exactly: `extends "res://scripts/ui/ModalScreen.gd"`,
   `signal back_pressed()`, hidden by default, instanced as a **child of
   MainMenu.tscn** and opened with `open()` - the same shape as `NewGameScreen`
   and `SettingsScreen` (no scene change). Add it to the `MenuScale.GROUP` and
   apply the menu scale on ready, like every other menu.
2. **Add a `LoadGameButton` to `MainMenu.tscn`** (`Panel/VBox`, between Continue
   and New Game). Disable it when `SaveManager.list_slots()` is empty, mirroring
   how `_refresh_continue_state()` disables Continue - and refresh it on the same
   beats.
3. **One row per slot**, built from `list_slots()`: the label, the node/party
   summary from `header`, the timestamp, and an autosave marker for
   `AUTOSAVE_SLOT`. Load on activate; offer Delete per row behind a confirm.
4. **Load calls `MainMenu._load_campaign_slot`** (promote it to a shared seam if
   the overlay cannot reach it cleanly). Keep the restore logic in one place.

## Landmines

- **A slot load currently launches straight into the map.** There is no
  `PrepScreen` yet (`B4-PREP-DEPLOYMENT`), so `launch_current_node()` goes
  directly to `GameMap`. That is correct for today and is a **one-line reroute**
  in `MainMenu._load_campaign_slot` once prep exists - do **not** design the
  picker around a screen that does not exist.
- **Do not offer a save the game cannot load.** `list_slots` already skips missing
  files, but `load_slot` still returns null on a corrupt or version-mismatched
  document. Show the same failure dialog MainMenu uses today
  (`_show_continue_error`) rather than silently doing nothing.
- **Do not sanitize slot ids - reject them.** `SaveManager.is_valid_slot_id` is an
  allow-list because a slot id becomes a filename. This only matters once ids are
  player-supplied (that arrives with manual save, in `B4-PREP`), but the picker
  must not invent ids of its own outside the allow-list.
- **Deleting the Continue target is already handled.** `delete_slot` clears the
  pointer; just call `_refresh_continue_state()` afterwards so the button
  disables.
- **Additive, as ever.** A player with no campaign save must see exactly today's
  menu behavior, with Load Game disabled.

## Tests owed

Extend `scripts/tests/test_main_menu.gd` (it already stubs `SaveManager`,
`GameState`, and `CampaignManager` - reuse those stubs):

- the Load button is disabled with no slots, and enables once one is written;
- the picker lists a row per written slot, newest first, and marks the autosave;
- activating a row restores through `GameState` and reaches
  `CampaignManager.launch_current_node()`;
- a corrupt slot shows the error dialog and does not stage `GameState`;
- deleting a slot removes its row and disables Continue when it was the target.

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

For behavior changes, update the owning `GDD_01`-`GDD_08` contract and flip the
`B1-CST` Slice 3 row in `GDD_10_Roadmap.md` in the same commit (DoD#1). Add a
session note and a newest-first row in `AGENT/Session Notes/INDEX.md` before
stopping.

Agents may push only `agent/**` branches. No PR is requested - push the branch
only; human review and merge are manual.
