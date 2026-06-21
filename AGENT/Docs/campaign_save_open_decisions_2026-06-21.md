# Campaign / Save Cluster (§2) — Open TECHNICAL Decisions Register

**Started:** 2026-06-21
**Last verified:** 2026-06-21
**Status:** Decisions register OPEN — code-facing choices the player-facing firming left open.
**Companion plan:** `campaign_save_technical_plan_2026-06-21.md` (the draft implementation plan;
references these as `[CST-n]`).
**Drives:** the §2 implementation slices. Mirrors the §1 pattern
(`input_controls_open_decisions_2026-06-21.md`): every entry carries options + a recommendation
+ a resolution line, walked one-by-one with the user.

**Inputs already resolved (do not re-litigate):**
`campaign_save_player_facing_firming_2026-06-21.md` (branches A–J),
`campaign_rules_firming_notes_2026-05-25.md`, `rng_determinism_design_2026-06-11.md` (rewind).

Legend: **[OPEN]** not yet asked · **[ASKED]** awaiting answer · **[RESOLVED]** logged.

---

## Dependency order (walk top→bottom)

Foundational keystones first (each shapes the schema), then flow, then save-model details,
then forward seams.

1. **[CST-1]** Save subsystem home + serialize/deserialize seam
2. **[CST-2]** Serialization codec ownership + the JSON UnitData layer (vs the in-memory snapshot)
3. **[CST-3]** Campaign / progression-graph model — where it lives
4. **[CST-4]** `CampaignRules` consolidation approach
5. **[CST-5]** Deployment-constraint data location (required/excluded/cap)
6. **[CST-6]** New Game → prep flow + how dev/test direct-map launches survive
7. **[CST-7]** Victory / between-map flow rewrite
8. **[CST-8]** Mid-battle suspend scope (the big one)
9. **[CST-9]** Integrity hash algorithm + protected-field set
10. **[CST-10]** Save file/dir layout + Continue pointer + autosave-vs-manual slots
11. **[CST-11]** Story-flip rule-mutation seam
12. **[CST-12]** Package A (`RngService`) sequencing relative to this cluster
13. **[CST-13]** Rewind mechanic fold-in (surfaced by CST-12; defer to §2 execution kickoff)

---

## [CST-1] Save subsystem home + serialize/deserialize seam  **[RESOLVED → A]**
The firming requires a serialize/deserialize seam isolated from file I/O (so single→zip export
and headless tests both work). Where does the save subsystem live?

- **A — New `SaveManager` autoload owning file I/O; pure `SaveData` seam separate from it.**
  `SaveData` (to/from Dict) has zero file knowledge; `SaveManager` does path/slot/disk/JSON.
- **B — Extend `GameState` with save/load methods.** Fewer new files; reuses the existing
  snapshot owner.
- **C — Static helper module only (no autoload).** Callers pass state in/out.

**Rec: A.** `SettingsManager` already proves the autoload-owns-disk pattern; a dedicated
`SaveManager` keeps `GameState` focused on live map state and makes the I/O-free seam testable
headless (the firming's hard requirement for the zip-sniff importer + integrity hash). `GameState`
stays the source of live state that `SaveData` reads from / writes to.

**Resolution:** **A (2026-06-21).** New `SaveManager` autoload owns file I/O / slots / export /
hash; pure `SaveData` (to/from Dict) is the I/O-free seam.

---

## [CST-2] Serialization codec ownership + JSON UnitData layer  **[RESOLVED → B]**
`GameState._snapshot_unit_data()` already dumps a UnitData to a Dict — but it stores **Vector2i**
(`tile_position`) and **live `InventoryEntry` Resource references** (deep-copied), neither of
which round-trips through JSON. The save needs a JSON-primitive serializer. Two questions: (a)
reuse the snapshot path or add a separate JSON layer, and (b) where the codec lives.

- **A — Dedicated `SaveCodec` helper (new module) with `unit_to_dict`/`unit_from_dict`,
  `entry_to_dict`/`entry_from_dict`, vector helpers. Keep `_snapshot_unit_data` for fast
  in-memory Retry.** Two serializers, each fit for purpose (Retry = fast Resource deep-copy;
  save = JSON primitives). Codec is pure + unit-testable.
- **B — Make `_snapshot_unit_data` itself JSON-safe and use ONE serializer for both Retry and
  save.** Single code path; but forces Retry through JSON-primitive conversion (slower, and the
  InventoryEntry round-trip must be lossless).
- **C — Put `to_save_dict()`/`from_save_dict()` methods on `UnitData` + `InventoryEntry`
  themselves.** Cohesive with the data; but thickens resources the project keeps thin.

**Rec: A.** Keeps the proven fast Retry path untouched, isolates JSON concerns in one testable
module, and gives the zip-sniff importer / integrity hash a clean dict to work on. The codec is
also the natural home for `format_version` field-shape handling.

**Resolution:** **B (2026-06-21) — user chose ONE serializer for both Retry and save.** A single
JSON-safe code path (cleaner single source of truth) replaces the dual-path rec.
**Implications baked into the plan:** (1) `_snapshot_unit_data`/`_restore_unit_data` are rebuilt
to emit/consume JSON primitives — `tile_position` Vector2i ↔ `[x,y]`, each `InventoryEntry` ↔ a
dict (`entry_type`/`weapon_id`/`item_id`/`uses_remaining`/`forged_mods`/equip bonuses). (2) The
`InventoryEntry` round-trip MUST be provably lossless (uses/durability/forge mods) — a hard
`test_save_codec` obligation, since Retry now depends on it too. (3) `conditions`/`active_modifiers`/
`growth_accumulators` are already Dict/primitive arrays and need only a JSON-validity assertion.
The logic still lives in one place (a `SaveCodec` module called by GameState), so "one serializer"
≠ "on GameState" — the seam stays extractable.

---

## [CST-3] Campaign / progression-graph model — where it lives  **[RESOLVED → A]**
Firming A2: model "what map is next/available" as an overworld-ready **graph node**, traversed
linearly for MVP. Today there is only `map_registry.json` (a flat pick-list) + `MapData`
(per-map authored content). Where does the campaign graph live?

- **A — New `CampaignData` definition (`campaign_main.json` or a `.tres` Resource) describing
  ordered/graph nodes that REFERENCE map_registry ids.** Maps stay reusable content; the
  campaign is its own data object. Linear MVP = an ordered node list (degenerate graph). This is
  also the future home for the deferred campaign-PACK (branch I3).
- **B — Extend `map_registry.json` with `next`/`unlock` fields so the registry *is* the graph.**
  Fewer files; but conflates "all maps that exist" with "this campaign's path," and a map can't
  appear in two campaigns with different successors.
- **C — Add `next_map_id` to `MapData`.** Simplest; but bakes campaign order into reusable map
  content and can't express branches/overworld nodes later.

**Rec: A.** Only A keeps maps reusable AND leaves room for the overworld/interludes/side-quests/
campaign-pack future without a schema reshape — exactly the forward-compat constraint A2 demands.
Sub-question if A: JSON (mod-friendly, matches map_registry + the homebrew goal) vs `.tres`
(typed, editor-authorable). **Rec: JSON** for consistency with the data-driven/homebrew intent.

**Resolution:** **A + JSON (2026-06-21).** New `CampaignData` (JSON) describing nodes that
reference `map_registry` ids; linear MVP = ordered single-path graph; future home for the
deferred campaign-PACK (I3).

---

## [CST-4] `CampaignRules` consolidation approach  **[RESOLVED → B]**
`CampaignRules.gd` is a Resource stub; the live rules are loose fields on `GameState`
(`permadeath_enabled`, `leveling_method`, `auto_promote_at_max_level`, `pair_up_enabled`,
`max_skills`, `max_inventory`, `exp_gaining_factions`). Many call sites read `gs.permadeath_enabled`
etc. The save must serialize one rules object. How to consolidate without churning call sites?

- **A — `GameState` holds `var campaign_rules: CampaignRules`; the existing loose fields become
  property getters/setters delegating to it.** Single source of truth; existing `gs.permadeath_enabled`
  reads keep working; save serializes `campaign_rules` only.
- **B — Hard-migrate every call site to `gs.campaign_rules.permadeath_enabled`.** Cleanest end
  state; larger diff + regression surface across many files.
- **C — Leave rules loose on GameState; serialize the loose fields directly.** No consolidation;
  but then `CampaignRules` stays a dead stub and the story-flip seam (CST-11) has no home object.

**Rec: A.** Lowest-risk path to a single serializable rules object; the delegating properties are
a thin shim, and `CampaignRules` becomes the real home for the story-flip seam + rewind charges.
Add rewind fields (`rewind_charges_per_map: int`, default per RNG-3) to `CampaignRules` here.

**Resolution:** **B (2026-06-21) — user chose the hard migration** for the clean end state. Every
call site moves to `gs.campaign_rules.<field>`. **Plan obligation:** an up-front grep sweep of
`permadeath_enabled`, `leveling_method`, `auto_promote_at_max_level`, `pair_up_enabled`,
`max_skills`, `max_inventory`, `exp_gaining_factions` across `scripts/` + tests, migrated as the
first step of the consolidation slice (slice 2); the loose GameState fields are then deleted, not
left as shims. `CampaignRules` gains `rewind_charges_per_map` (RNG-3 default). Larger diff
accepted in exchange for no dead stub + no delegation indirection.

---

## [CST-5] Deployment-constraint data location  **[RESOLVED → B]**
Firming C2: each map declares `required_units` (forced deploy), `excluded_units` (locked out),
`deployment_cap`, and deploy tiles. These reference roster `unit_id`s, which are
**campaign-specific**, while `MapData` is reusable content. Where do the constraints live?

- **A — On the campaign progression node (CST-3 CampaignData); MapData keeps `player_start_tiles`
  as the placement tiles + a `deployment_cap` default.** Constraints that name roster units live
  with the campaign; geometry stays with the map.
- **B — All on `MapData` (`required_units`/`excluded_units`/`deployment_cap`).** One place per
  map; but bakes campaign-roster knowledge into reusable map content.
- **C — Split: `deployment_cap` + tiles on MapData (geometry/balance), required/excluded on the
  campaign node (roster identity).**

**Rec: C.** `deployment_cap` and start tiles are properties of the *map's* balance/geometry and
belong on `MapData`; `required_units`/`excluded_units` name specific roster members and belong on
the *campaign node*. Clean separation, no reusability loss.

**Resolution:** **B (2026-06-21) — constraints all on the campaign node.**
`required_units` / `excluded_units` / `deployment_cap` all live on the `CampaignData` node, so a
campaign fully owns its deployment shape. **One physical carve-out:** `player_start_tiles` stay on
`MapData` — they are concrete tiles on that map's grid, so the node references them as placement
anchors rather than re-declaring geometry (a node optionally subsetting/overriding tiles is a
later enhancement, not MVP). Net: node owns *who/how-many*, map owns *where the tiles are*.

---

## [CST-6] New Game → prep flow + dev/test direct-map launches  **[RESOLVED → "everything is a campaign"]**
Today New Game (`NewGameScreen`) picks ONE map + 4 rules and `change_scene`s straight to
`GameMap`. The `map_registry.json` mixes campaign maps with dev/test maps (`map_900` hotseat,
`map_950` promotion, faction demo). With a campaign model, New Game should create a fresh
campaign save and route to the **prep screen** for node 1 — but the dev/test single-map launches
must survive (they're load-bearing for testing).

- **A — New Game = pick campaign (one for MVP) + rules → create save → prep screen for node 1.
  Keep a separate DEBUG-only "Test Map" launcher (the existing map dropdown, gated to
  `OS.is_debug_build()` / dev maps) that bypasses the campaign and launches a single map with a
  synthetic one-node campaign + default roster.** Players get the campaign; devs keep direct launch.
- **B — Keep the map dropdown in New Game; treat every map as a one-node campaign.** Minimal flow
  change; but no real campaign progression UX and the player sees test maps.
- **C — Two menu entries: "New Campaign" (real flow) and "Test Map" (current behaviour).**

**Rec: A** (≈ C — the test launcher can be its own debug entry). New Game becomes the real
campaign flow; the existing per-map launch is preserved behind a debug gate so headless tests +
manual test maps keep working. The synthetic single-node campaign lets a test map reuse the same
prep/launch code path.

**Resolution:** **"Everything is a campaign" (2026-06-21) — refines the rec.** Rather than a
separate debug map-launcher, **every map becomes a single-node campaign for now**, so there is ONE
code path (campaign select → prep → launch) and no special debug route. Implications baked in:
1. The New Game map-dropdown is replaced by a **campaign selector**; each `map_registry` entry is
   auto-wrapped as a 1-node campaign (dev/test maps surface as `is_dev_only` campaigns, filterable
   from the player-facing list), alongside any authored multi-node `CampaignData`.
2. The selector **defaults to the last-started campaign, else the most-recently-imported** one
   (uses the `SaveManager` last-played pointer + import timestamps — ties to [CST-10]).
3. **NEW — campaign-owned rules (expands [CST-4]/G2):** each `CampaignData` carries a rules block
   where each rule is either an **author MANDATE** (locked; player cannot change) or a **DEFAULT**
   (player-editable starting value). At new-campaign creation, `campaign_rules` is seeded from this
   block; the rules UI shows mandated rules as locked and defaults as editable. The save records
   which rules were mandated (so tinkering/story-flip honors authorial intent + the G2 tinkerer
   warning). This makes the 4 New Game toggles campaign-scoped, not global.

---

## [CST-7] Victory / between-map flow rewrite  **[RESOLVED → A]**
Today: victory → `GameOverScreen` (standings + Retry/Quit), no next-map. New flow must: advance
the progression pointer, auto-save, and route to the next node's prep (or campaign-complete).
The GameOverScreen also becomes the multi-choice **defeat** menu (B5). Question: how to split
victory vs defeat handling.

- **A — Split the screens: a `MapResultsScreen` (victory → standings → "Continue" advances
  pointer + autosaves + → prep) and refit `GameOverScreen` as the defeat multi-choice menu
  (reload recent / reload any / main menu / [rewind]).** Clear single responsibility each.
- **B — Keep one screen, branch internally on victory/defeat.** Fewer files; but the two states
  now have very different button sets + side effects (advance vs reload), so the branch grows.
- **C — Victory has no screen; auto-advance straight to prep with a results toast.** Fastest loop;
  but loses the standings moment the current design shows.

**Rec: A.** Victory and defeat now do opposite things (progress forward vs roll back), so one
screen each keeps each flow legible and testable. Reuse the existing standings renderer in the
victory screen. The "advance pointer + autosave + route to prep" lands in the new results screen.

**Resolution:** **A (2026-06-21) — split screens**, with a preservation note. New
`MapResultsScreen` (victory: standings → Continue → advance node + autosave → next prep) +
`GameOverScreen` refit as the defeat multi-choice menu. **Preserve the standings/rankings
renderer as a reusable component** — earmarked for a future **PvP scenario mode** (added to the
deferred tracker), so the ranked-standings logic is extracted/kept, not deleted.

---

## [CST-8] Mid-battle suspend scope  **[RESOLVED → between-action, human-controlled]**  ← biggest technical risk
B3: persistent re-loadable mid-battle suspend. The `GameState` TODO already flags that suspend
needs **live enemy UnitData** (enemies respawn fresh today) + any live terrain mutations, beyond
the player-only Retry snapshot. The cost scales with *when* a suspend may be taken.

- **A — MVP suspend allowed ONLY at player-phase-start boundaries.** Serialize: full roster +
  enemy UnitData + positions, turn #, phase, per-faction activation/turn-order cursor, map id +
  graph position, rules, rewind charges, RNG `{map_seed, history_hash}`, pair-up registry,
  threat-range `_watch_set`/`_danger_mode`, cursor tile. **No** mid-action, mid-animation, or
  mid-enemy-phase state. Bounded, deterministic, far smaller.
- **B — Suspend at any moment (full fidelity).** Must also capture mid-AI-turn scheduler state,
  in-flight animations, partial move/attack resolution, undo stacks. Large + fragile; many edge
  cases to serialize and restore exactly.
- **C — Suspend = "save & quit" only (consumed/locked until resumed), player-phase boundary.**
  Smaller still; but contradicts B3 (persistent, re-loadable, not consumed).

**Rec: A.** Player-phase-boundary suspend captures everything that matters for "stop and resume
later" while sidestepping the entire class of mid-resolution state — the dominant complexity/bug
source. It satisfies B3 (persistent + re-loadable). Any-moment suspend (B) can be a later
enhancement once `RngService`/replay (Package A) exists, since true mid-action resume overlaps
the rewind machinery. **Note:** even A requires the enemy-UnitData serialization the TODO calls
out — that's the real new work here, independent of timing.

**Resolution:** **Between committed actions, any human-controlled faction (2026-06-21) — upgraded
from the phase-start rec after a code feasibility check.** Code finding: the "has-acted" state is
already centralized in `TurnManager._unit_states` (`{Unit: READY/DONE}`) and the activation
position is `_active_faction_idx`+`_turn_order`+`_activation_mode`; a clean **idle FREE cursor**
boundary already exists between committed actions. So between-action suspend costs only
`_unit_states` (serialized as `{unit_id: state}`) + the activation cursor ON TOP of the phase-start
state set — everything else (roster, live enemy UnitData/positions, turn/phase, RNG
`{seed,history_hash}`, pair-up registry, threat `_watch_set`/`_danger_mode`, cursor tile) is the
same. **Gate:** Suspend is offered only when the cursor is idle FREE (no selection / no in-flight
move/attack/animation) AND the active faction is human-driven. Because F9 hotseat override makes
the enemy faction human-driven through the SAME idle-FREE boundaries, this yields **mid-(hotseat)-
enemy-phase suspend for free**. **Still excluded** (needs Package A replay): mid-move/animation/
attack-resolution and AI-driven (non-hotseat) enemy phases. **Test obligations:** restore from an
ALTERNATING-mode mid-round suspend; restore with a mix of READY/DONE units; restore enemy board
from serialized state (not `_spawn_units`).

---

## [CST-9] Integrity hash algorithm + protected-field set  **[RESOLVED → A + author-designatable]**
I4: on export, attach an integrity hash; on load, recompute → mismatch = warn-and-continue;
author-marked **protected fields** altered = stronger secondary warning. Need the concrete method.

- **A — SHA-256 over the canonical (sorted-key) JSON of the save dict with the `integrity` field
  removed; protected fields = `format_version`, the rules block, and the progression position.**
  Standard, available via Godot `HashingContext`/`Crypto`; canonicalization makes the hash
  reproducible across pretty-print/whitespace edits.
- **B — Lightweight checksum (CRC32 / simple sum).** Cheaper; weaker, more false "matches" after
  edits.
- **C — Per-field hashes for protected fields + a whole-file hash.** Most precise warnings; more
  code.

**Rec: A.** SHA-256 of canonical JSON (hash field excluded) is the clean primitive; for the
protected-field secondary warning, recompute a second hash over just the protected sub-dict so we
can tell "something changed" (whole-file) from "a protected thing changed" (sub-hash) without
per-field machinery. Protected set = rules + format_version + progression position (the fields
that silently break the game if hand-edited). Tinkerable fields (roster stats, label, gold) only
trip the soft whole-file warning.

**Resolution:** **A + author-designatable protected fields (2026-06-21).** Two SHA-256 hashes
(whole-file over canonical JSON sans the hash field; second over the protected sub-dict).
**Refinement:** the protected-field set is NOT fixed — a campaign author can designate **any
field(s)** as protected via a `protected_fields` list in `CampaignData`, ON TOP OF a mandatory
baseline (`format_version`, the rules block incl. `mandated_rules`, progression position). The
save stamps the effective protected-field list it was built with so the loader recomputes the
sub-hash over exactly those paths. Whole-file mismatch = soft warning; protected mismatch =
stronger secondary warning; unparseable/unknown-version = the only hard stops.

---

## [CST-10] Save file/dir layout + Continue pointer + autosave/manual slots  **[RESOLVED → A]**
B2 auto+manual save, B6 slot menu, A4 Continue = resume-most-recent. Concrete layout?

- **A — `user://saves/` dir; manual slots `slot_1.json … slot_N.json`; a dedicated
  `autosave.json`; a dedicated `suspend.json`; a tiny `saves_index.json` holding the
  `last_played` pointer (file + timestamp) for Continue.** Slot menu = scan dir + read each
  file's header block. Autosave never overwrites a manual slot.
- **B — Single saves dir, every save a peer slot incl. autosave/suspend, Continue = newest mtime.**
  Simpler; but autosave/suspend clutter the manual slot list and "newest mtime" is fragile across
  filesystems/export.
- **C — One save file per campaign (no slots); branching via export only.** Minimal; loses the
  in-app multi-slot the firming asked for.

**Rec: A.** Separate autosave + suspend from the manual slot pool (so autosave can't clobber a
deliberate slot, and suspend is its own resumable thing), and use an explicit `last_played`
pointer rather than mtime so Continue is deterministic. Header block (chapter/playtime/party/
badges/label) lives at the top of each save for cheap slot-menu reads. **Web caveat (I2a):**
export/import goes through the browser download/upload sandbox; in-app slots still use `user://`.

**Resolution:** **A (2026-06-21).** `user://saves/` with manual `slot_N.json`, dedicated
`autosave.json` + `suspend.json`, and a `saves_index.json` holding the `last_played` pointer (+
import timestamps, feeding the CST-6 campaign-selector default). Slot menu reads each file's header
block. Autosave never clobbers a manual slot; suspend is its own re-loadable file.

---

## [CST-11] Story-flip rule-mutation seam  **[RESOLVED → A]**
G2/G3: rules are player-locked but **authored story events** may flip a rule, with an explicit
in-game notification. No cutscene/event system exists yet. What do we build now?

- **A — Build the seam only: `CampaignRules`/`GameState` API `apply_rule_flip(rule, value,
  reason)` that mutates the rule, records it (for the read-only rules view + save), and emits an
  EventBus `campaign_rule_flipped` signal a notification UI listens to. Leave the TRIGGER source
  (event/cutscene system) unbuilt — call it from a debug/test hook for now.** Seam ready; trigger
  arrives with the future event system.
- **B — Build seam + a minimal map-data "on_complete rule flips" hook** so a map can flip a rule
  on victory without a full event system.
- **C — Defer entirely** (rules immutable for MVP); add the seam when the event system lands.

**Rec: A.** The firming explicitly wants the seam + notification now (it shapes the schema's
rules region + tinkerer warning). A real trigger source needs an event system that doesn't exist;
exposing the API + signal + record now satisfies the schema/forward-compat need without inventing
a half event system. B is a reasonable small step if you want at least one authored flip
demonstrable; flag if so.

**Resolution:** **A (2026-06-21).** Build the seam only: `apply_rule_flip(rule, value, reason)`
(mutates + records for the read-only rules view + save) + EventBus `campaign_rule_flipped` +
notification UI. Trigger source (event/cutscene system) deferred; call from a debug/test hook
meanwhile.

---

## [CST-12] Package A (`RngService`) sequencing  **[RESOLVED → C]**  ← the note's explicit open question
Rewind hooks (rule + charges + defeat-menu entry) are inert without the actual Turnwheel, which
is hard-blocked on `RngService` (Package A, `rng_determinism_design_2026-06-11.md`). Where does
Package A sit relative to this cluster?

- **A — Build §2 spine now with rewind HOOKS only (rule/charges/menu entry, mechanic disabled);
  schedule Package A as its OWN later cluster; the rewind mechanic re-surfaces after both land.**
  Matches the firming; keeps §2 shippable without the deepest determinism work.
- **B — Pull Package A forward to BEFORE/ALONGSIDE §2** so suspend (CST-8) and rewind share the
  determinism/replay machinery and aren't built twice.
- **C — Build Package A FIRST, then §2** (rewind ships with the cluster).

**Rec: A**, with one caveat to weigh: CST-8's any-moment suspend (option B there) overlaps
Package A's replay machinery, so if you ever want true mid-action suspend, doing Package A first
(C) would avoid building suspend twice. Since CST-8's rec is the *bounded* player-phase suspend
(which does NOT need replay), A stands — §2 ships independent of Package A, and Package A becomes
the gate for BOTH the rewind mechanic and any future any-moment suspend. Decide CST-8 first; it
informs this.

**Resolution:** **C (2026-06-21) — Package A FIRST, then §2 (user override of rec A).** Build
`RngService` (Package A, `rng_determinism_design_2026-06-11.md`) before the §2 spine, so the
foundation is solid and the cluster builds on real determinism. **Consequences baked into the plan:**
1. **§2 execution is now sequenced AFTER Package A.** The immediate next execution step is Package
   A, not §2 slice 1. Package A needs its own implementation plan (separate cluster doc).
2. The suspend block's `rng {map_seed, history_hash}` (CST-8) become **genuinely meaningful**
   (deterministic), not placeholders.
3. **Rewind is no longer forced to be hooks-only** — with Package A present, the actual Turnwheel
   mechanic (J2/J3/J4) is UNBLOCKED. **New follow-on scoping question (resolve at §2 execution
   kickoff):** does §2 now FOLD IN the rewind mechanic, or still ship §2 with rule+charges+menu
   hooks and do the Turnwheel as the immediate follow-on? (Rec lean: keep §2's spine focused on
   save/prep/flow, land the mechanic right after — but it's a live option now.) Tracked as
   **[CST-13]** below.
4. CST-8's MVP suspend stays between-action; Package-A determinism leaves the door open for
   any-moment suspend later without rework.

---

## [CST-13] Rewind mechanic fold-in (surfaced by CST-12 → C)  **[OPEN — resolve at §2 execution kickoff]**
With Package A built first, the actual Turnwheel mechanic is unblocked. Does it ship inside §2 or
right after?

- **A — §2 spine ships with rewind HOOKS only (rule + charges + defeat-menu entry); Turnwheel
  mechanic is the immediate follow-on cluster.** Keeps §2 focused on save/prep/flow; mechanic
  lands next against a finished save/charge substrate.
- **B — Fold the Turnwheel mechanic INTO §2** now that it's unblocked. One cluster delivers
  rewind end-to-end; larger §2 scope.

**Rec: A (lean).** Keep §2's spine focused; land the mechanic immediately after against the
finished charge-persistence + RNG substrate. Not blocking until §2 execution begins — revisit
then. (No need to decide during planning.)

**Resolution:** _pending — defer to §2 execution kickoff._

---

# Resolution Log
(newest first)

- **2026-06-21 — Forward-seam batch resolved (batch 4) — register COMPLETE.** [CST-11] **A** —
  build the story-flip seam + `campaign_rule_flipped` notification only; trigger source deferred.
  [CST-12] **C** (user override) — **Package A (`RngService`) is built FIRST, then §2**; this
  re-sequences execution (Package A is the next build step, needs its own plan), makes the suspend
  `rng` fields real, and unblocks the rewind mechanic → surfaced **[CST-13]** (fold the Turnwheel
  into §2 vs ship hooks-only + mechanic next; rec hooks-only, deferred to §2 execution kickoff).
- **2026-06-21 — Save-model batch resolved (batch 3).** [CST-8] **between committed actions, any
  human-controlled faction** (upgraded from phase-start after a code feasibility check — the delta
  is just `_unit_states` + activation cursor, both on `TurnManager`; F9 hotseat ⇒ free mid-enemy-
  phase suspend). [CST-9] **A + author-designatable protected fields** (two SHA-256 hashes;
  `CampaignData.protected_fields` on top of a mandatory baseline). [CST-10] **A** —
  `user://saves/` with manual slots + dedicated autosave + suspend + `saves_index.json`
  last-played pointer.
- **2026-06-21 — Flow batch resolved (batch 2).** [CST-5] **B** — deployment constraints
  (required/excluded/cap) all on the `CampaignData` node; `player_start_tiles` stay on `MapData`
  as physical anchors. [CST-6] **"everything is a campaign"** — every map auto-wraps as a 1-node
  campaign (one code path, no debug launcher); campaign selector defaults to last-started / most-
  recently-imported; **NEW: each campaign carries rule MANDATES (locked) or DEFAULTS (editable)**,
  expanding [CST-4]/G2. [CST-7] **A** — split MapResultsScreen (victory) / GameOverScreen (defeat
  menu); **preserve the standings renderer for a future PvP scenario mode** (deferred tracker).
- **2026-06-21 — Foundational quartet resolved (one-by-one walk, batch 1).** [CST-1] **A** —
  `SaveManager` autoload + I/O-free `SaveData` seam. [CST-2] **B** (user override of the dual-path
  rec) — ONE JSON-safe serializer for both Retry and save; `InventoryEntry` lossless round-trip
  becomes a hard test obligation. [CST-3] **A + JSON** — new `CampaignData` graph referencing map
  ids. [CST-4] **B** (user override) — hard-migrate every rule call site to
  `gs.campaign_rules.*`, delete the loose fields (no shims).
- **2026-06-21 — Register opened.** Twelve code-facing decisions [CST-1..12] extracted while
  drafting the technical plan, ordered by dependency. Grounded in a fresh read of `GameState`,
  `CampaignRules`, `NewGameScreen`, `GameOverScreen`, `GameMap` launch path,
  `PairUpRegistry.serialize/restore`, `MapData`, `InventoryEntry`/`UnitData` fields,
  `map_registry.json`, and `SettingsManager`'s ConfigFile persistence pattern.
</content>
</invoke>
