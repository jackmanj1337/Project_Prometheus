---
Type: register
Status: RESOLVED 2026-06-25n
Last verified: 2026-06-25
Register: VIL-1..9
Resolved-in: 2026-06-25n / 2026-06-25p (VIL-9 capture-victory addendum)
---

# Village / Map Events (#11) + the Interactive-Trigger Substrate — Player-Facing Design + Open Questions Register

**Started:** 2026-06-25n (first A4 sub-cluster — "story / event-driven map content").
**Status:** [VIL-1..9] **RESOLVED** (VIL-1..8 2026-06-25n; VIL-9 capture-victory objective type added
2026-06-25p) — end-shape-first walk; all owner calls taken.
**A4 — Story / event-driven map content.** This pass firms **visitable / destructible villages
(#11)** and, in doing so, pins the **A4 keystone substrate** every other A4 thread reuses: a new
class of **player-initiated "interactive" MET trigger** fired from a unit action-menu entry. Village
is **config over four existing substrates**, not a new system.

**Method (owner pref `feedback_feature_walk_end_shape_first`):** end-shape established via questions
**first** (what a village must DO + its authoring surface), *then* substrate/reuse analysis, *then*
the reuse-vs-bespoke verdict. End-shape answers (2026-06-25n owner calls): visit = **dedicated Visit
action**; outcome = **full MET action list (reuse)**; raze = **reuse the destructible-object path**;
persistence = **F6 flags**; visit geometry = **author's choice per village**.

**Source:** scope-map #11 (village visit/destroy, rewards, branching) + the 2026-06-25m A4 tee-up +
two owner scope additions made mid-walk (2026-06-25n): the **terrain More-Info tile-action discovery
list w/ required characteristics + author-hideable actions**, and the **objective removal-disposition
rule** for Rout/Eliminate.

**Code grounding (substrate already exists):**
- `scripts/shared/TileActions.gd` — the shared availability source for unit-on-tile actions, read by
  **both** `ActionMenu` and the HUD terrain More-Info panel ("same source of truth"). **Already
  reserves `shop`/`visit`/`activate`** as placeholder ids next to the wired `seize`/`escape`; its
  doc comment says a future implementation "only has to extend `is_available()`." This is the exact
  extension point for Visit + the discovery list.
- `scripts/ui/ActionMenu.gd` — `Seize`/`Escape` are **context-sensitive entries gated through
  `TileActions.is_available(action, unit, tile, turn)`**, shown only when the active map authors a
  matching condition. A `Visit` entry is a sibling of these. (Hidden-when-unavailable rows already
  collapse via the VBox; Wait always shown.)
- MET framework `[MET-1..9]` (RESOLVED 2026-06-21h) — `MapData.map_events: Array[Dictionary]`,
  trigger → optional flag `condition` → ordered `actions` → `once` latch (`map_events_fired` in §2).
  v1 actions = `reveal_tiles`/`flag`/`spawn` (+`grant_item` via `[CEX-15/18]`, +`set_ai`);
  `dialogue`/`gold`/`recruit` land with their seams. Every existing trigger is a **passive EventBus
  reaction** — VIL adds the first **interactive** ones.
- DTR `[DTR-1..8]` (RESOLVED 2026-06-21g) — a breakable is a **real `Unit`-in-disguise** (roster-
  quarantined) taking the full damage pipeline (no dodge/counter), HP/Def durability, firing
  `on_break` → the `object_broken` MET action list. `hp:1` degenerates to one-hit destruction.
- `[F6]` flag store (`[MET-6]`) — two scopes (map-flags + campaign-flags), set by a `flag` action,
  read by `condition` guards. `[RCR-3]` — roster `recruit()`/`capture()` API + the **MET `talk`
  trigger contract** A4 builds against (the unit-targeted twin of Visit).
- `scripts/resources/ObjectiveCondition.gd` — the win/lose evaluator (`defeat_boss`/`protect`/
  `escape`/`seize` watchers over `unit_ids`/`tiles`/`turns`). Today re-evaluated on `unit_died`; the
  VIL-8 pin requires re-evaluation on **unit-removed / faction-changed** too.

---

## Verdict (the keystone)

> **A village = config over four reused substrates — NOT a bespoke system.** Physical village + raze
> = the **DTR destructible object**; visit reward = the **MET trigger→action runner**; persistence /
> branching = **`[F6]` flags**; the Visit action itself = a **`TileActions` entry firing a new
> _interactive_ MET trigger** (sibling to Seize/Escape). The single genuinely-new piece — the
> **interactive-trigger substrate** ([VIL-2]) — is **not village-specific**: Recruit's `talk`
> (`[RCR-3]`) and the reserved `shop`/`activate` are its other configs. Design it once.

---

## Register

### [VIL-1] Village = config over DTR + MET + F6 + the interactive-trigger substrate  **[RESOLVED]**
Not a bespoke "village system." A village is authored as a destructible `map_object` (DTR) carrying a
**Visit interactive trigger** ([VIL-2]) whose `actions` are the standard MET vocabulary ([VIL-4]),
gated/persisted by `[F6]` flags ([VIL-5]). No new engine beyond [VIL-2]/[VIL-6].
- **Resolution:** RESOLVED 2026-06-25n — config, not a system. Reuse verdict above.

### [VIL-2] Interactive-trigger substrate — the A4 keystone (shared with Recruit `talk`)  **[RESOLVED]**
Every existing MET trigger is a *passive* EventBus reaction (`unit_died`/`turn_reached`/
`object_broken`). Villages and recruitment need a **player-initiated** trigger: a unit ends its action
on/beside a valid target, the player chooses a menu entry, and **that** fires the MET trigger.
- **Shape:** a `TileActions`/action-menu entry (`visit`, and `talk` per `[RCR-3]`) gated exactly like
  Seize/Escape; on press → `action_chosen.emit("visit")` → MapCursor fires a MET interactive trigger
  carrying the **target ref** (object id for Visit; the partner unit for Talk). Runs the authored
  `actions` list at the same deferred safe point as other MET actions (`[MET-8]`).
- **Configs:** Visit (object/tile-targeted), Talk (unit-targeted, `[RCR-3]`), and the reserved
  `shop`/`activate` `TileActions` ids — all the same substrate, parameterized by target kind + gate.
- **Resolution:** RESOLVED 2026-06-25n — one interactive-trigger substrate; Village + Recruit are its
  first two configs. Recruit's conversation side (task #2) consumes this, does **not** re-invent it.

### [VIL-3] Visit geometry — author's choice per village (carries BOTH raze models)  **[RESOLVED]**
A destructible village-object is a `Unit`-in-disguise → it **occupies its tile** (impassable), which
forces a geometry choice. Owner call: **author picks per village**, so both models ship:
- **(a) Occupied-object** — village is the DTR object on its tile; the player **visits from an
  adjacent tile** (same geometry as Talk / as attacking the object). The enemy **razes by attacking
  the object** down to 0 HP (DTR pipeline; `hp:1` = one-hit raze) → fires `object_broken`.
- **(b) Passable-tile** — village is a passable terrain tile the unit **stands on** to visit (classic
  FE feel). The raze side is **not** DTR HP but a **`tile_seized`-by-enemy trigger** (enemy ends on
  the tile → raze action list). No object HP in this mode.
- A per-village authoring flag selects (a) vs (b). Both raze paths converge on the same
  `flag`/action vocabulary (set `razed_<id>`, run the raze action list).
- **Resolution:** RESOLVED 2026-06-25n — author's choice; carry both geometries + both raze models.

### [VIL-4] Visit outcome = the full (growing) MET action list  **[RESOLVED]**
A visit's reward is a standard MET `actions` list — `flag`, `grant_item` (to convoy/unit), `dialogue`
(rides F13), `recruit` (the `[RCR-3]` action), a future `gold` action, `spawn`, etc. The village is
**config**; its reward richness is bounded by — and grows with — the MET action vocabulary, never by a
parallel village-only outcome set. (`gold` is a thin new MET action surfaced here; `dialogue`/
`recruit` land with their own seams per `[MET-3]`.)
- **Resolution:** RESOLVED 2026-06-25n — full MET action list (reuse); no bespoke reward set.

### [VIL-5] Persistence & lock-out — F6 flags + the `once` latch  **[RESOLVED]**
A visit sets an `[F6]` flag (`visited_<id>`, campaign-scope for branching / later-map recruitment); a
raze sets `razed_<id>`. The Visit entry's gate ([VIL-2]) requires **not-visited AND not-razed**;
`once:true` latches the fired event into `map_events_fired` (`[MET-5]`, already reserved in §2). No
new save field beyond the existing flag store + fired-set.
- **Resolution:** RESOLVED 2026-06-25n — F6 flags + `once` latch; visit gated on `¬visited ∧ ¬razed`.

### [VIL-6] Terrain More-Info = the full tile-action discovery list + required characteristics  **[RESOLVED]**
Owner addition. The terrain More-Info panel must enumerate **every** tile-specific action that exists
on the hovered tile — including ones the current unit **cannot yet** take — and display the
**required characteristics** for each (e.g. "Visit", "Seize — requires Lord", "Open — requires a
Lockpick"). `TileActions` evolves from a boolean `is_available(): bool` to a per-action descriptor
`{ id, available: bool, requirement: String, hidden: bool }`. The **action menu** shows only
`available` entries (unchanged behavior); the **More-Info readout** shows all non-hidden entries with
their requirement text. One source of truth → menu and readout still never disagree.
- **Resolution:** RESOLVED 2026-06-25n — extend `TileActions` to descriptors; readout = all
  non-hidden actions + requirements, menu = available only.

### [VIL-7] Author-hideable / secret actions  **[RESOLVED]**
Owner addition. Some actions must NOT advertise themselves — secret shops, secret doors, hidden
recruit paths. A per-action **`hidden`** axis (an authored flag, optionally **flag-revealable** via
an `[F6]` condition) suppresses the entry from the More-Info readout entirely until revealed. This is
the secrecy counterpart to [VIL-6]'s transparency: a *visible-but-gated* action advertises its
requirement; a *secret* action is absent until its reveal condition flips, after which it behaves as a
normal gated entry.
- **Resolution:** RESOLVED 2026-06-25n — per-action `hidden` (flag-revealable) visibility state on
  the `TileActions` descriptor; coexists with [VIL-6] requirement display.

### [VIL-8] Objective removal-disposition — Rout/Eliminate vs recruit/escape/story-removal  **[RESOLVED → forward-pin to the objective system]**
Owner addition + the carried-in `[DSP]` Capture-victory pin both land here: **Rout** (defeat all
enemies) and **Eliminate** (defeat target unit) need defined behavior when a watched unit leaves the
map by a cause **other than death** — recruit faction-flip (`[RCR]`), escape off-map, capture-carry
off-map (`[DSP]`), or a story `remove`/despawn action.
- **Rule (defined here):** Rout/Eliminate **evaluate on _hostile-to-player presence_, not on death
  events.** A watched target counts as removed when it is no longer a *living unit hostile to the
  player present on the map*. Re-evaluate the condition on **unit-removed / faction-changed** signals,
  not just `unit_died`.
- **Disposition by cause (owner call 2026-06-25n):**
  - **Death** → satisfied (eliminated).
  - **Recruited to the player (or a player-allied faction)** → satisfied (no longer hostile).
  - **Recruited by a still-hostile third faction** → **NOT** satisfied (still your enemy, under new
    management). [owner: "key on still-hostile."]
  - **Escape (off-map)** and **story-action removal** → **author-set `pass | fail` per objective.**
    `pass` = treated as removed/satisfied; `fail` = the objective can no longer be met → triggers
    defeat (e.g. "don't let the boss flee" = escape:`fail`).
- **Scope:** the *rule* is firmed here; the *build* is the `ObjectiveCondition` /
  objective-system work (an `ObjectiveCondition` field for the escape/story-removal `pass|fail`
  setting + re-eval hooks on faction-change/unit-removed). **Cross-pin:** `[RCR]` (recruit flip),
  `[DSP]` (capture-carry + the Capture-victory pin), Escape objective, and A5 (this co-owns the
  death/removal disposition path with the A5 death-inventory rule set). Carried as A4 task #4.
- **Resolution:** RESOLVED 2026-06-25n (rule) — forward-pinned to the objective system for build.

### [VIL-9] Capture-victory objective type (the win-condition half of the `[DSP]` pin)  **[RESOLVED — addendum 2026-06-25p]**
The `[DSP]` Capture-victory pin has two halves: the **removal-disposition** when a unit is captured
(firmed in [VIL-8]) and the **win-by-capture** objective type (this item). **No genuine fork** — it
mirrors the existing `seize`/`defeat_boss` patterns: a new **`ObjectiveCondition.type = capture`** over
`unit_ids`, **satisfied when each named target is in the captured state** (its `captured:<id>` flag is
set). The `captured:<id>` flag is produced by the **A2** capture-carry mechanic (`[DSP]`) /
`[STY-6]` non-lethal `sleep` + carry-off — so *how* a target becomes captured stays A2; this item only
defines the **objective that reads the flag.** Reuses the `ObjectiveCondition` `unit_ids` watcher; no
new evaluation machinery.
- **Resolution:** RESOLVED 2026-06-25p — `ObjectiveCondition.type=capture` over `unit_ids` satisfied by
  the `captured:<id>` flag (set by A2); mirrors `seize`/`defeat_boss`. Build rides the objective system.

---

## F1 schema-lock reservations (this register)
- **No new save field** for villages themselves — `visited_<id>`/`razed_<id>` ride the `[F6]` flag
  store (reserved) + the visit/raze events latch into `map_events_fired` (`[MET-5]`, reserved).
- **Authoring (not save):** the per-village geometry flag ([VIL-3]); per-village `actions` lists
  ([VIL-4]); the `TileActions` descriptor `requirement`/`hidden` fields ([VIL-6]/[VIL-7]); the
  `ObjectiveCondition` escape/story-removal `pass|fail` setting ([VIL-8]).

## Cross-references
- Consumes: `[MET-1..9]` (runner/triggers/actions/flags), `[DTR-1..8]` (destructible object + raze),
  `[F6]`/`[MET-6]` (flag store), `[CEX-15/18]` (`grant_item`).
- Shares the interactive-trigger substrate ([VIL-2]) with `[RCR-3]` (`talk`) and the reserved
  `shop`/`activate` `TileActions` ids.
- [VIL-8] cross-pins `[RCR]`, `[DSP]` (Capture-victory pin + capture-carry), the Escape objective,
  and the A5 death/removal-disposition path.
