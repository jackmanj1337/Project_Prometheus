---
Role: dated
Type: plan
Status: Re-derived 2026-08-17 against RPD-1..18, EPUX and PHB; scope widened 2026-08-18 to build the DSX dependent-choice layer — Slices 1-3 built against the superseded design
Last verified: 2026-08-18
Decision source: ../registers/responsive_prep_deployment_open_questions_2026-08-12.md (RPD-1..18); ../design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md (EPUX prep-hub section); ../registers/prep_hub_open_questions_2026-06-23.md (PHB-5, PHB-7)
Tracker: B4-PREP-MAP-DEPLOYMENT-2026-07-22
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# `B4-PREP-DEPLOYMENT` — Prep Screen — re-derived 2026-08-17

> **Re-derived by `R1`, instance (a).** This document was authored 2026-07-14 and cited `CST-5`
> and `CST-6` — **nothing else**. It named neither `PHB` (which governs the prep hub, ruled
> 2026-06-23) nor `RPD` (which ruled deployment, 2026-08-13), because `RPD` did not exist when it
> was written. That is the blind spot
> [`r1_plan_corpus_precedence_diff_2026-08-17.md`](../design/r1_plan_corpus_precedence_diff_2026-08-17.md)
> §1.2 describes: a plan that predates a register cannot cite it, so it scores clean on every
> citation-based check while being a month behind the design.
>
> **The headline is not staleness. Slices 1–3 are BUILT, against the design this re-derivation
> supersedes.** `scripts/ui/PrepScreen.gd` (338 lines) and `scenes/ui/PrepScreen.tscn` exist,
> `CampaignManager.launch_current_node()` routes to them, and manual save works. So
> `B4-PREP-MAP-DEPLOYMENT` is a **migration of working code**, not a greenfield build. Scope §3
> accordingly.

## 1. Corrections folded in

| # | What this plan said | What is ratified | Where |
|---|---|---|---|
| 1 | Slice 2 builds **one PrepScreen** listing the party, with placement on it | Deployment splits across **two hub entries** — Manage Roster owns *who*, Map Preview owns *where* — both editing one live `DeploymentPlan` | `[RPD-6]` (closed by precedence), `EPUX` prep-hub §Top-level node menu |
| 2 | "a **deploy toggle** per unit", placement by list order | The author **numbers start positions**; the engine **auto-fills from the deployment roster in order**; the player **swaps**. Placement is never a mandatory chore — the board starts full | `EPUX` §Map Preview, `[RPD-7]`/`[RPD-8]` |
| 3 | Placement gesture unspecified | **Select-then-select, committing on the second selection, no confirm step.** One gesture for touch, mouse and gamepad. Touch drag is an optional shortcut, never the sole route. Visible swap preview retained | `[RPD-7]`/`[RPD-8]` |
| 4 | "Begin Battle is **gated** until the plan is legal" | Begin Battle is **always visible and focusable, but not activatable**, exposing a player-facing unmet reason. Not hidden, not an inert disabled control | `[EPUX-07]` (2026-07-26), restated `[RPD-15]` |
| 5 | Reason strings unspecified | The unmet reason is a `REQ` predicate returning an `[EPUX-02]` two-state result (absent → hidden, gated → shown disabled with reason), evaluated **in the shell** so adapters cannot drift. **No sixth vocabulary** | `[RPD-10]`, `[EPUX-02]`, `[EPUX-04]` |
| 6 | Required-unit-dead case: "**Decide what that case does** (block launch? warn?)" | **Ruled.** Author-time validation where possible; runtime shows the **specific** contradiction and uses an author-selected fallback or block, **never a silent drop**. Required-ness is a `REQ` predicate over the roster — a property of *the mission*, not a badge on the unit | `[RPD-16]` |
| 7 | Suspend-Retry case: "**Decide it**; either skip the reroute or clear the payload" | **Ruled, and neither option as framed.** The plan is a **staged transaction committing at Begin Battle**; **suspend discards the stage**; campaign Retry is a snapshot restore through `MapLedger`. The packet's proposed "explicit safe transition" was **rejected as a third primitive**. "Never allow a plan that spawn ignores" becomes **structural** — there is no committed plan to ignore until Begin Battle commits one | `[RPD-17]`, `[PHB-5]`, `[PHB-7]` |
| 8 | "**Later, once `B3-PHB` lands:** convoy/trade/shop panels. **Do not design them now**" | They **are** designed. Manage Roster is an **open registry of roster-config panels**; Explore is subject-first services | `EPUX` prep-hub §Manage Roster, §Explore |
| 9 | "Panels are an open registry… does not bite Slice 1-3, constrains Slice 4" | **It bites Slice 2 now.** `[RPD-11]`'s quick card is a **projection of the Manage Roster registry filtered by a `quick` flag** — Loadout/Skills/Details/Swap are shipped *defaults*, not the set | `[RPD-11]` |
| 10 | "`B3-PHB` is **NOT a prerequisite** for a first slice" | True for Slice 1 and still true of the seam. **False for the re-scoped Slice 2**, which lives inside the hub. The tracker already carries `B3-PHB-REGISTRY-2026-07-19` as a dependency | `EPUX` prep-hub |
| 11 | Nothing about size classes | Map Preview is a **canvas**: surfaces occupy the **canvas region only, never the control band**, at every size class. Three simultaneous panes are **rejected** | `[RPD-1..4]`, `UBS-4`, `[EPUX-03]` |
| 12 | Nothing about mission facts | Objective **always**; defeat condition and deployment constraints on demand in Compact, all three at Medium/Expanded | `[RPD-12]` |
| 13 | Nothing about inspection | **Placement and inspection are named modes** with a visible current-mode indicator and an explicit toggle, so the same tap target is safe in both | `[RPD-13]` |
| 14 | Nothing about remembering a plan | The plan is remembered **firmly within a prep visit**, **best-effort across visits**, falling back **per slot** when a unit died, left, changed class, or start tiles changed. Generalizes `EPUX`'s subject-memory tiering — **no new preset concept** | `[RPD-14]` |
| 15 | Nothing about empty slots | **Neutral capacity**, not warnings. An exact-count campaign rule is a `REQ` predicate → Begin Battle disabled with the authored reason | `[RPD-9]` |

**Confirmed unaffected**, so the walk need not revisit them:

- **"Do not persist the deployment plan… no new F1 save row is owed."** Correct, and now doubly
  ratified: `[PHB-7]` (immediate commit to party state, no hub-suspend snapshot, re-derive on
  re-entry) and `[RPD-18]`, which re-derived `PHB-7` correctly without knowing it existed. Note
  `[RPD-14]`'s within-visit memory is *not* a save row — it is live state, discarded with the stage.
- **`required_units` / `excluded_units` / `deployment_cap` on `CampaignNode`.** `[RPD-16]` says
  required-ness is "a property of *the mission*, not a badge on the unit" — which is exactly the
  node-scoped array these fields already are. No schema change, and **do not** mistake `[RPD-16]`
  for a reason to move them onto units.
- **`deployment_cap` is -1 for uncapped and `CampaignData` rejects 0.** Unchanged.
- **Benched units gain nothing.** Unchanged (technical plan §4).
- **Additive: a launch path with no prep plan behaves exactly as today.** Unchanged.

## 2. What is built, and what is wrong with it

Verified against the tree 2026-08-17.

**Built and correct:**

- `scripts/shared/DeploymentPlan.gd` validates a plan against the party, `player_start_tiles` and
  the node constraints. `[RPD-6]` names this seam as already-built.
- `GameState.next_map_deployment` stages the plan; `GameMap._spawn_units` (`GameMap.gd:294`)
  consumes it and falls back to today's roster-order rule when absent.
- `CampaignManager.launch_current_node()` routes to the prep scene — the single insertion point.
- Manual save over `write_campaign_slot`, with the `is_valid_slot_id` allow-list finally taking
  player-supplied input.

**Built against the superseded design — these are the migration:**

1. **`PrepScreen.build_plan()` (`:221-227`) assigns tiles by *selection order*.**

   ```gdscript
   for i in _selected_ids.size():
       if i < _map_data.player_start_tiles.size():
           plan[_selected_ids[i]] = _map_data.player_start_tiles[i]
   ```

   This is the roster-order inference the 2026-07-14 plan set out to *replace*, relocated into the
   screen rather than removed. Placement is a side effect of list ordering (`_move_unit`, `:209`),
   so there is no map-side placement at all and no swap gesture. The ratified model is **authored
   numbered start positions, auto-filled in roster order, then swapped** — auto-fill is the same
   idea, but the player's control over it is a *swap on the map*, not reordering a list.

2. **`_on_unit_toggled` (`:200`) is the per-unit deploy toggle** superseded by correction 1/2 —
   *who* moves to Manage Roster, *where* to Map Preview.

3. **Begin Battle is implemented backwards from the ruling.** `_refresh_validation` (`:239-242`)
   sets `_begin_button.disabled = not errors.is_empty()`, and `_on_begin` (`:245`) re-checks and
   returns. `[EPUX-07]`/`[RPD-15]` require focusable-but-not-activatable.

4. **One reason string, not a per-entry unmet reason.** `_validation.text = errors[0]` shows the
   *first* error in a shared label. `[RPD-10]`/`[EPUX-02]` want the reason attached to the entry
   that is gated, resolved through `REQ`'s display path.

### 2.1 The shell implements the ruling backwards — and it is not prep-scoped

`ModalScreen._is_focus_disabled()` (`scripts/ui/ModalScreen.gd:327-328`) reads:

```gdscript
func _is_focus_disabled(control: Control) -> bool:
    return control is BaseButton and (control as BaseButton).disabled
```

Both `_first_focusable` (`:119`) and `_collect_focusable_controls` (`:321`) use it to **exclude
disabled buttons from focus traversal** — the precise opposite of *"disabled entries remain in the
focus order so their reason is reachable by keyboard, controller, and screen reader"*.

**This is shell-level and affects all five availability surfaces, not just prep**, which is exactly
where `[EPUX-04]` and `[RPD-15]` put the decision. Fixing it inside `PrepScreen` would be the
per-adapter drift both rulings exist to prevent. **Spun out as its own row** —
`SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17` — and `B4-PREP-MAP-DEPLOYMENT` consumes it rather
than reimplementing it.

## 3. Re-scoped slices

Slice 1 stays closed. Slices 2–3 are **built and superseded**; the work below migrates them.

1. **Slice 1 — deployment plan seam. IMPLEMENTED 2026-07-14, unaffected.** Shipped contract:
   `GDD_01_Data_Contracts.md` §Deployment Plan Contract — read that, not this plan.
2. **Slice 2a — authored numbered start positions and auto-fill.** Give `player_start_tiles` an
   authored order that is the fill order, and auto-fill the plan from the deployment roster.
   Replaces `build_plan()`'s selection-order mapping. The board starts full.
3. **Slice 2b — Map Preview as a canvas, with select-then-select swap.** Placement and inspection
   as named modes with a visible indicator and explicit toggle (`[RPD-13]`); surfaces confined to
   the canvas region at every size class (`[RPD-1..4]`); visible swap preview (`[RPD-8]`).
4. **Slice 2c — Manage Roster owns *who*.** Deployment selection moves into the roster-config
   panel registry, and the quick card becomes a projection of that registry filtered by `quick`
   (`[RPD-11]`). **Depends on `B3-PHB-REGISTRY`.**
5. **Slice 2d — readiness.** Begin Battle always visible and focusable; per-entry unmet reasons
   through `REQ`. **Depends on `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17`.**
6. **Slice 3 — manual save. BUILT.** Re-home it as the hub's **Save** entry (`EPUX` top-level node
   menu) rather than a button on a standalone prep screen. Behaviour unchanged.
7. **Slice 4 — plan memory.** `[RPD-14]`'s tiering: firm within a visit, best-effort across, per-slot
   fallback on death/departure/class change/start-tile change.

**Ordering note.** 2a before 2b (a swap gesture needs a filled board to swap), 2d after the shell
row, 2c after `B3-PHB`. 2a is the only one with no external dependency and is where to start.

### 3.1 Scope widened 2026-08-18 — this row builds the dependent-choice layer

> **OWNER RULING 2026-08-18.** Slice 2b's select-then-select gesture is built as the shared
> **dependent-choice layer** of `[DSX-S4]`..`[DSX-S9]`, with deployment placement as **consumer 1**
> — not as a placement-local gesture that something later extracts.

`[DSX-S9]` (2026-08-15) named deployment placement as the layer's fifth consumer and ruled that the
layer must **absorb** this row's ratified gesture "rather than shipping a second implementation of
it". Because `B4-PREP-MAP-DEPLOYMENT` is a **v0.8.0** row and the whole `PREP-V1` line is not, this
row's gesture ships **first** — so the only way that requirement can be structural rather than a
promise is for the producer to be here.

**What that adds to slice 2b:**

- **One state machine, one commit rule, one cancel rule** (`[DSX-S4]`), with the *kind* —
  *counterpart* (another instance, displaced or swapped) or *operation* (a transform applied to the
  first pick) — selecting only how the second set's rows render. Deployment placement is the
  **counterpart** kind; the forge at `PREP-V1-S07` is the operation kind and is what will prove the
  two-kinds claim is real.
- **The first pick is focus, not a reservation** (`[DSX-S7]`). Nothing is held — `[TSV-2]` was ruled
  moot. Cancelling at stage 2 returns to stage 1 with no mutation. **The vocabulary is fixed as
  `pinned`, never "staged"**, so `DRC-30`'s cart/staged collision cannot return through wording.
- **The empty slot is an entry in the set** (`[DSX-S8]`), so one gesture covers both a move into
  free space and a swap. No second interaction to learn or test.
- **The layer adds no confirmation of its own** (`[DSX-S6]`) — which is already this row's ratified
  behaviour, since a swap is reversible before Begin Battle and earns no `CAU-4` tag.
- **Stepping back out of a dependent set keeps the pinned pick** (`[DSX-S13]`); the pin drops only
  on leaving the pool step entirely.

**Boundary — this row builds the layer, not the shell.** `[DSX-S1]`'s holder · pool · detail
composition stays at `PREP-V1-S02`. Map Preview is a **canvas** (`[RPD-1..4]`), so placement
consumes the layer's state machine without needing the shell's regions, and `[DSX-S5]`'s
"dependent set takes the pool, result and verb take the detail" binds the consumers that live
*inside* the shell. If the split proves unworkable in build, escalate by widening `PREP-V1-S02` —
never by growing a second shell here.

**Four rows now consume what this one produces:** `PREP-V1-S03` (convoy transfer into a full
holder), `PREP-V1-S07` (forge), `DRC-V1-S05` (Trade), and cap-full replacement for skills,
techniques, battalions and loadout outside these epics. Decision source for all of it is
[`prep_economy_implementation_plan.md`](prep_economy_implementation_plan.md) §6, row 6.

## 4. What already exists (verified 2026-07-14, re-verified 2026-08-17)

Do not rebuild these, and do not change their schema — they were authored *for* this track.

- **`CampaignNode` carries all three deployment constraints** — `required_units: Array[String]`,
  `excluded_units: Array[String]`, `deployment_cap: int` (-1 = uncapped; `CampaignData` validates
  `-1 or >= 1`). Confirmed present at `CampaignNode.gd:36-40`. Their comment says it outright:
  "[CST-5] Deployment constraints live on the NODE, not the map. Consumed by B4-PREP-DEPLOYMENT."
  **No schema change is owed**, and `[RPD-16]` endorses the node scoping.
- **`MapData.player_start_tiles: Array[Vector2i]`** is the placement surface, and `GameMap` already
  centroids it for the opening camera position. Slice 2a gives its *order* meaning.
- **`CampaignManager.launch_current_node()`** (`CampaignManager.gd:296`) is the "prep → map" seam and
  already routes to the prep scene. **Every route into a map funnels through that one call** — the
  campaign "Next" on `GameOverScreen`, and `MainMenu._load_campaign_slot` (Continue and the Load
  Game picker) — so prep is inserted in ONE place, not three.
- **`CampaignManager.write_campaign_slot(slot_id, save_label)`** is built and tested and is the
  manual-save seam. It returns false when no campaign is active and captures through
  `GameState.capture_campaign_save`.
- **`SaveManager.is_valid_slot_id`** is an allow-list, not a sanitizer, because a slot id becomes a
  filename. Reject a bad id; never "clean" it.
- **`LoadGameScreen`** remains the model for a surface that names a slot and lets its owner run the
  restore, rather than growing its own capture path.

## 5. Landmines

Surviving unchanged:

- **The bare single-map launch has no campaign.** `NewGameScreen` launches a map directly through
  `GameState.configure_next_map` with no `CampaignManager` position — and `write_campaign_slot`
  returns false for exactly that reason. Prep must not appear on that path. `[CST-6]`'s "every map is
  a 1-node campaign" auto-wrap is **`B6-CAMPAIGN-SHARING`'s**, not this track's.
- **Bare-map Retry stays direct.** `[RPD-17]` confirms it. Gate any reroute on an active campaign or
  `NewGameScreen`'s Retry dies.
- **Permadeath already skips the incapacitated** in `_spawn_units`. Prep must not offer a dead unit
  as deployable.
- **Panels are an open registry, not an enum** (`[SAC]`, and `AGENTS.md`'s architecture principle).
  Now binding on Slice 2c, not Slice 4.

Now ruled, and the plan's "decide it" is discharged:

- **A required unit that is permanently dead** → `[RPD-16]`. Author-time validation where possible;
  runtime shows the **specific** contradiction with an author-selected fallback or block; never a
  silent drop. The author-time half rides `[DLUX-10]`'s existing structured warning contract — do
  not invent a second one.
- **Retry after a suspend-resume** → `[RPD-17]`. **Suspend discards the stage.** The old worry — that
  `next_map_suspend_payload` would make `GameMap` take the suspend spawn path and ignore the plan —
  dissolves, because no plan is committed until Begin Battle. **Do not build the "explicit safe
  transition"**: it was rejected as a third primitive beside two that already cover the case.
  Retry itself remains a snapshot restore through `MapLedger`, which `MapLedger` was already ruled to
  consume.
- **Two entrances is still true**, and `[RPD-17]` keeps its reasoning: a campaign Retry reroutes to
  prep for both defeat and victory. Prep stays a **pure plan-authoring surface** — it must never
  re-apply the roster policy or re-resolve the map binding, or a first-node Retry throws away the
  snapshot-restored party.

## 6. Tests owed

Carried forward, with the superseded assertions corrected:

- `test_game_map_scene`: an explicit plan places the named units on the named tiles; an absent plan
  falls back to today's roster-order rule unchanged.
- Plan validator: `deployment_cap` respected (and -1 uncapped); `required_units` cannot be benched;
  `excluded_units` cannot be deployed; a plan naming a unit not in the party is rejected; a plan with
  more units than `player_start_tiles` is rejected.
- `test_campaign_manager`: `launch_current_node` routes to prep for a campaign; the bare map launch
  is untouched.
- `test_game_over_sequencing`: a campaign Retry (defeat AND victory) routes to prep with the party
  rolled back to map-start and the previous plan pre-selected; bare-map Retry still reloads directly;
  **a Retry on a suspend-resumed map discards the stage** rather than stranding the player.
- **Auto-fill (new):** the board starts full in authored start-position order; a roster shorter than
  the slot list leaves neutral empty slots and does **not** raise a warning (`[RPD-9]`).
- **Swap (new):** select-then-select commits on the second selection with no confirm; the swap
  preview is visible; the same path works from keyboard/gamepad without a pointer.
- **Readiness (corrected):** Begin Battle with an illegal plan is **visible and focusable**, and
  activating it does nothing — the old "gated until legal" assertion is superseded and must be
  rewritten, not deleted.
- **Modes (new):** inspection never moves a unit; the current-mode indicator reflects the active mode.
- Manual save: a rejected slot id fails loudly and writes nothing.

## 7. Environment gotchas

- After adding any `class_name` script, run `godot --headless --path . --import --quit-after 1000`
  before the tests, or the global class registry will not resolve the new type and every suite
  referencing it fails to parse.
- That import also generates `.uid` sidecars. `check_docs` check 9 fails on any untracked `.uid`, and
  the pre-commit hook runs `check_docs` over the whole tree, so a stray sidecar blocks an unrelated
  commit. Stage new sidecars with their scene/script.
- Commit attribution: use `AI-Tool` / `AI-Model` / `AI-Run-ID` / `AI-Workspace` trailers; the human
  stays git author. No `Co-authored-by` model trailers.

## 8. Verification and commit discipline

```bash
bash scripts/check_env.sh
python3 AGENT/Docs/check_docs.py
bash scripts/ci/check_rng_usage.sh
bash run_tests.sh
```

For behavior changes, update the owning `GDD_01`–`GDD_08` contract (prep's surface contract is
`GDD_07_UI_UX.md`) and flip the `B4-PREP-DEPLOYMENT` row in `GDD_10_Roadmap.md` in the same commit
(DoD#1). Add a session note and a newest-first row in `AGENT/Session Notes/INDEX.md` before stopping.

---

## Appendix — historical resume point (2026-07-14)

Superseded; kept because it records why the track paused. The branch is long merged and v0.7.7 has
since shipped.

> Branch `agent/claude/save-spine-handoff` (tip `072994a`). The v0.4.0 Windows playtest preempted
> this work. The Load Game picker had never been rendered — it was covered by headless tests only,
> and it changed the Main Menu's shape (five buttons; each save row three lines). Session note for
> the picker: `AGENT/Session Notes/2026-07-14i.md`.

Successor to
[`b1_cst_slice3_load_picker_handoff_2026-07-14.md`](b1_cst_slice3_load_picker_handoff_2026-07-14.md).
`B1-CST` closed 2026-07-14. The campaign flow technical plan (§4,
`campaign_save_technical_plan_2026-06-21.md`) gave this track its scope:

> show required (forced) + roster minus excluded; player deploys up to `deployment_cap`, assigns
> placement onto `player_start_tiles`; manual Save; Begin Battle → GameMap. Benched units gain
> nothing.
