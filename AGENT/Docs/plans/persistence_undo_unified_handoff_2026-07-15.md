---
Role: dated
Type: plan
Status: Target design
Last verified: 2026-07-15
---

# Unified Persistence & Undo - Design Handoff - 2026-07-15

Successor context to [`b4_prep_deployment_handoff_2026-07-14.md`](b4_prep_deployment_handoff_2026-07-14.md).
This document is a **design handoff, not an implementation plan.** It records the
decisions reached in the 2026-07-15 persistence design discussion so the next
session can write the sequenced implementation plan without re-deriving them. All
behavior below is `Target design` - **nothing here is built yet**, and some
existing code is explicitly slated to be scrapped.

The prompt for this discussion was memoed as "have the persistence talk FIRST,
before more B4 prep work." That talk is now held; this is its output.

## Resume point

- Branch context: the seams below were verified against code on
  `agent/claude/2026-07-14/prep-deployment` (tip `1df833e`). Re-verify before
  editing - do not trust these line numbers blindly.
- **The v0.4.0 Windows playtest still preempts this work** (per the B4 handoff and
  the v0.4.0 memory). A returned playtest checklist pauses persistence work at a
  clean commit; its repairs belong on the v0.4.0 build branch.
- The Retry->prep reroute (commit `1df833e`) is **design-only, no code** - B4 Slice
  2 still builds it. It interacts with this design (Retry becomes a ledger read),
  so sequence the two together or land this first.

## The unifying claim

Retry, Rewind, and Suspend are three reads of ONE within-map history structure.
Campaign Save is the layer above it (party + position + rules, no board). Load is
dumb - it names a slot and lets the restore path branch on whether the document
carries a live board. This is the spine the whole design hangs on.

The discriminator already exists and works: a `SaveData` document with a populated
`map_runtime.map_path` resumes a board; one without it routes through
`CampaignManager.launch_current_node`. **Preserve this discriminator** - most of
the unification is deleting special-casing that predates it.

## Layer 2 - the within-map history is a dual-resolution DECAYING LEDGER

Not a ring buffer. Two tiers that age differently, each an author budget in
`CampaignRules`:

- **Fine tier (activations):** one snapshot taken BEFORE each unit activation. The
  atom is a whole unit activation - move and attack are NOT separate undo points
  (confirmed decision). Budget `undo_activations`; ring-like, keep the last A.
- **Coarse tier (round starts):** one snapshot per round boundary. Budget
  `undo_rounds`, which MAY be infinite. Append-only and decimated; even infinite is
  O(rounds) full boards, which is affordable - decimation is what makes
  long-horizon undo cheap.
- **Prune policy** runs after each push and keeps `(last A activations) UNION (last
  R round-starts)`. The author preset "every action in the current round + the
  round-start of the last x rounds" is just the fine budget scoped to the current
  round. Model the policy as data (three parameterizations of one prune function),
  not a hardcoded mode `match` - matches the open-registry architecture principle.

**Every ledger snapshot must be SUSPEND-complete** (all factions' units + turn
state + cursor + RNG timeline + Pair Up), NOT the lighter party-only snapshot Retry
takes today. A mid-battle rewind must restore enemy HP/position and whose turn it
is; the current `take_map_snapshot` only covers the player party because at map
start only the party varies. The suspend-complete serializer already exists inside
`GameState.capture_suspend_save` - lift its `map_runtime` block into the ledger
entry format.

**Retry becomes `restore(round-0 boundary)`** on this ledger. Scrap
`GameState.take_map_snapshot` / `restore_map_snapshot` as a separate path and
re-express Retry as a ledger read. This is the deliberate "scrap old code" moment.

## Determinism - the real anti-scum

Each ledger snapshot carries the RNG timeline; rewinding or reloading restores
RNG-at-that-point, so replaying identical actions yields identical outcomes. A
player who reloads cannot fish for better luck - only DIFFERENT choices change
results, which is legitimate play. This is already true for Retry via RNG-2
(`restore_map_snapshot` calls `RngService.from_save_dict`; `capture_suspend_save`
captures it); the ledger extends it to every activation snapshot.

Consequence for the safety rule below: determinism removes the LUCK dimension of
save-scumming, leaving only the DECISION-undo dimension - which is exactly what the
rewind budget governs. That is why the durable-mid-battle warning is conditioned on
the rewind budget being finite, and not on luck at all.

## Layer 1 / storage - one slot namespace, kind intrinsic to the document

A suspend save and a campaign save are already the same `SaveData` doc. Unify the
storage:

- **DELETE** the special suspend slot: `SUSPEND_FILENAME` (`suspend.json`) and the
  `save_suspend` / `load_suspend` / `delete_suspend` / `has_suspend` API in
  `SaveManager`, plus the `LAST_PLAYED_SUSPEND` continue-kind branch. A suspend
  becomes "a slot whose document carries `map_runtime`."
- Keep `SaveManager.is_valid_slot_id` (the player-supplied-id allow-list) and the
  numbered/named slot store as the single namespace.
- **Suspend persists the WHOLE ledger** (decision), so a reloaded suspend can still
  rewind into its pre-suspend history.
- One "Save" action captures whatever is live: board present -> `mid_map` document;
  between maps -> `between_map` document. Automatic, from the discriminator.
- `LoadGameScreen` lists all occupied slots and shows each kind as a row label
  ("Resume battle - Turn 4" vs "Continue - Chapter 3"); the restore path already
  does the right thing per slot.

## The save policy - an author-tunable list of slot-classes

Lives in `CampaignRules` next to the undo budgets. A policy is a LIST of
slot-classes; a class is `{count, accepts, consumed_on_load, label}` where
`accepts` is `between_map | mid_map | any`. One schema spans the three target
presets:

- **Classic GBA FE:** `{count:3, accepts:between_map, consumed_on_load:false}` +
  `{count:1, accepts:mid_map, consumed_on_load:true}`.
- **Single consumable:** `{count:1, accepts:any, consumed_on_load:true}`.
- **30 interchangeable:** `{count:30, accepts:any, consumed_on_load:false}`.

**Enforced at the game's save/load API + UI ONLY - never the file format.** No
crypto, no checksums. A determined player exports and backs up the plain file, and
that is fine (it also serves legit backups, bug reports, and modding). This posture
is a decision, not a gap.

## Autosave - folded into the policy as triggered auto-written classes

An autosave rule is `{trigger, keep, label, consumed_on_load:false}`:

- **`trigger` is an OPEN-REGISTRY event id**, not a hardcoded pre/post enum. Adding
  a trigger must not require an engine edit (the `shop_exit` ask below is the proof:
  it is neither pre nor post battle). Built-in triggers to ship:
  - `battle_start` (= pre-battle)
  - `battle_end` (= post-battle; **this is what the existing commit-time autosave
    becomes** - a generalization, not a new concept)
  - `menu_area_exit` / `shop_exit` (autosave on leaving a shop or other menu area)
  - plus author-bindable custom events (round_end, boss_defeated, a campaign flag)
    = the "authorable trigger."
- **`keep`** is the rule's own rotation depth: keep the N most recent, delete the
  oldest on the N+1th write; `keep:1` = a single rotating autosave.
- **Each rule owns its own pool, SEPARATE from the manual `count` budget.**
  Autosaves never eat manual slots (30 manual + keep-3 pre-battle autos = 33 files),
  and a full manual pool can never block an autosave from succeeding.
- Autosaves are always durable. An empty autosave list = no autosave (hardcore).
- Kind falls out of fire time: `battle_start` / `battle_end` / `shop_exit` autos are
  `between_map` and therefore always safe. Only an authorable trigger firing
  MID-battle produces a `mid_map` autosave.

## Two safety rules (both authored 2026-07-15)

1. **HARD INVARIANT - an autosave may rotate an OLDER AUTOSAVE, but must NEVER
   overwrite a manual save.** Enforce STRUCTURALLY: tag every saved doc `origin:
   manual | auto` (+ `rule_id` for autos); autosave rotation selects its overwrite
   target ONLY from `origin:auto` of the SAME `rule_id`, so manual slots are
   physically absent from the candidate set (and other rules' autos are untouched).
   Add a defensive `assert(target.origin != "manual")` + a unit test as
   belt-and-suspenders, but the guarantee comes from the candidate set.
2. **NON-BLOCKING campaign-builder warning** when mid-battle (`mid_map`) saves are
   durable (`consumed_on_load:false`) AND rewind (`undo_activations` /
   `rewind_charges`) does NOT default to infinite. Rationale: a durable board-reload
   bypasses a finite rewind budget = self-contradiction; if rewind is already
   infinite there is no contradiction (and determinism means it was never
   luck-scumming). `between_map` durable slots are ALWAYS safe. The provided
   documentation must carry the same warning. Per DoD#2, land the check WITH the
   feature - model it on `AGENT/Docs/check_docs.py`.

## Code inventory - keep / generalize / scrap

Verified 2026-07-15; re-verify line numbers before editing.

- **Keep / reuse:** `GameState.capture_suspend_save` (the suspend-complete
  serializer - becomes the ledger entry codec); `RngService.to_save_dict /
  from_save_dict` (per-snapshot determinism); `SaveManager.is_valid_slot_id` and the
  slot store; the `map_runtime`-absence load discriminator;
  `GameState.capture_campaign_save` / `configure_campaign_resume` (Layer 1, largely
  unchanged).
- **Generalize:** `take_map_snapshot` -> `push_history` at suspend-completeness;
  `restore_map_snapshot` -> `restore_history(index)`; the commit-time autosave ->
  the `battle_end` trigger.
- **Scrap:** the separate Retry snapshot path (once Retry is a ledger read); the
  special `suspend.json` storage + `save_suspend/load_suspend/delete_suspend/
  has_suspend` + `LAST_PLAYED_SUSPEND` branch; `GameOverScreen._on_retry`'s direct
  `restore_map_snapshot` call (re-point at the ledger).
- **Confirmed authored-only, needs a real consumer:** `CampaignRules
  .rewind_charges_per_map` exists in schema/serialization only - no code spends a
  charge today. Rewind is genuinely unbuilt.

## Suggested build/scrap sequence (for next session to refine into the plan)

1. **Generalize the snapshot** to suspend-completeness and make it the ledger entry
   format (foundation everything reads).
2. **The decaying ledger + Retry-on-ledger:** two-tier stack + prune policy;
   re-express Retry as `restore(0)`; scrap the old retry path. Ship with tests.
3. **Rewind:** the `undo_activations` / `undo_rounds` budgets consuming the ledger.
   This is the DEFERRABLE step if it fights hardware/memory - measure one serialized
   board snapshot before committing to budgets.
4. **Unified slot namespace:** collapse `suspend.json` into slots; add `origin`
   tagging; suspend persists the whole ledger.
5. **Save policy + autosave triggers:** the slot-class list, the trigger registry,
   rotation, the never-overwrite-manual invariant, and the durable-mid_map warning +
   its `check_docs.py` check.

## Documentation DoD reminders for the implementing session

- Behavior changes here touch the save/campaign contracts: update `GDD_01_Data
  _Contracts.md` (CampaignManager / save-document contracts), `AGENT/Docs/campaign
  _rules.md` (the new undo budgets + save policy are campaign rules), and
  `GDD_07_Screens_Panels.md` (Load/Save UI), flipping the matching `GDD_10_Roadmap
  .md` status in the SAME commit (DoD#1).
- The durable-mid_map warning is a checkable rule - its `check_docs.py` extension
  ships in the same change (DoD#2).
- After adding/retitling this or any doc, run `python3 AGENT/Docs/gen_docs_index.py`
  and commit the regenerated `INDEX.md` / `REGISTERS.md` (check 18).
