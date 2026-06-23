---
Type: design
Status: Player-facing firming — pass complete
Last verified: 2026-06-23
---

# Campaign / Save Cluster — Player-Facing Firming

**Started:** 2026-06-21
**Last verified:** 2026-06-21
**Status:** Player-facing firming PASS COMPLETE — branches A–J resolved via interview.
Ready to drive the code-side §2 implementation plan + decisions register (next, not yet written).
**Method:** Walk the design tree root→leaf, resolve dependencies one branch at a time.
Every question carries a recommendation; resolved answers are logged inline.
**Companion (code side, written later):** the §2 implementation plan + decisions register.

## Firmed MVP scope — one glance
**In the MVP spine:** linear (overworld-ready graph) map→map progression · between-map prep
(deploy/bench, map-authored required/excluded/cap, player-assigned placement, manual save,
launch) · human-readable JSON campaign saves with `format_version` + `save_label` + integrity
hash · in-app slots **and** filesystem export/import (single `.json`, zip-sniffing importer) ·
persistent re-loadable mid-battle suspend · Continue = resume-most-recent · multi-choice Game
Over menu · rewind RULE + charge persistence + defeat-menu entry (mechanic via Package A) ·
campaign rules player-locked / story-flippable / tinkerer-warned.
**Deferred from this cluster:** convoy/inventory (D) · shop/economy (E) · recruit (F) · Pair
Up persistence + prep pairing (H1) · Support (H2) · Rescue (H3) · campaign-PACK format (I3) ·
the actual rewind mechanic (J, needs `RngService`/Package A). **Do-not-forget tracker:**
`planning_backlog_2026-06-20.md` **§2b** lists each deferred item + what it needs to re-surface.
**Hard dependencies:** rewind ⇒ `RngService` (Package A, `rng_determinism_design_2026-06-11.md`).
**Cross-version save transfer:** NOT a concern until 1.0 (I5) — keep `format_version` as cheap
insurance, but write no migration code pre-1.0; save compat may break freely between versions.
**Forward-compat constraints baked in:** progression-graph node model (overworld later);
serialize/deserialize seam + `format_version` (multi-file packs later); item/gold fields
reserved (convoy/shop later); roster-growth save-supported (recruit later).

## Grounding (current code state — verified 2026-06-21)
- **No campaign loop exists.** New Game (`NewGameScreen.gd`) picks ONE map + 4 rules
  (`permadeath`, `auto_promote`, `leveling_method`, `pair_up`), loads a roster, launches
  `GameMap`. Victory → `GameOverScreen` shows ranked standings + **Retry** (in-memory
  snapshot restore) / **Quit** (→ Boot → MainMenu). No next-map, no disk save.
- **`GameState`** holds `player_roster: Array[UnitData]`, `party_gold`, `party_items`
  **between maps in memory only**. `_map_start_snapshot` is an in-memory Retry snapshot
  (player units + gold/items + Pair Up registry), NOT a disk save.
- **`reset_map_state()`** clears the Pair Up registry between maps (pairings do NOT persist).
- **`CampaignRules.gd`** is a Resource stub mirroring the 4 rules + `max_skills`/
  `max_inventory` + `exp_gaining_factions`; not yet wired (rules still loose on GameState).
- **MainMenu** has New Game / Settings / Quit only. **No Continue button yet** (GDD_07
  mocks one as greyed "Phase 2").
- Roster comes from `res://data/roster/default/` (6 units) via `load_default_roster()`.
- `max_inventory = 8` defined but **not enforced**; no convoy, shop, trade, or recruit code.

## Locked priors (from `campaign_rules_firming_notes_2026-05-25.md`)
- Campaign rules chosen at New Game, stored in the save, stable for the save's life
  unless a deliberate migration feature is built.
- Pair Up / Rescue mutually exclusive until a combined ruleset is designed.
- Support long-term data versioned separately from map runtime state.

---

# Design Tree

Legend: **[OPEN]** not yet asked · **[ASKED]** awaiting answer · **[RESOLVED]** logged.
Each node: the question, options, **Rec:**, and a Resolution line.

## A. Campaign spine & scope  (ROOT — gates everything)
- **A1 — Scope of THIS cluster.** **[RESOLVED] MVP spine first.** Backbone now (linear
  map→map progression, disk save + Continue, mid-battle suspend, minimal prep/deploy);
  convoy/shop/recruit/support layered as follow-on slices.
- **A2 — Campaign structure.** **[RESOLVED] Linear NOW, overworld-ready architecture.**
  MVP walks a fixed linear order, BUT the design must not block the eventual target: an
  **Awakening-style overworld map selector** with campaign chapters + interlude chapters +
  wandering/random encounters + unlockable side-quests. **Forward-compat constraint:** model
  "what map is next / available" as a **progression registry/graph node** (e.g. each node
  declares unlock conditions + successors), which the MVP traverses linearly. An overworld
  node-selector then sits on top later without reshaping the save schema. Linear MVP = a
  degenerate single-path graph.
- **A3 — Between-map flow.** **[RESOLVED] Between-map prep surface.** Victory results →
  prep screen (deploy / convoy / save) → launch next map. Home for all C/D/E features.
- **A4 — "Continue" semantics.** **[RESOLVED] Resume most-recent activity.** Continue
  follows a "last touched" pointer: if the newest save is a mid-battle suspend, it resumes
  that battle; otherwise it loads the latest between-map save into the prep screen. A
  separate "Load Game" slot picker covers older slots.

## B. Save / load model  (depends on A)
- **B1 — Slots.** **[RESOLVED] In-app slots + filesystem export/import.** Multiple in-app
  save slots for ease of use, PLUS **save export/import to the local filesystem** for
  cross-device play and direct save-file tinkering. **Stated intent:** give users the tools
  to **write and distribute homebrew campaigns** → see new **branch I**. Implies a
  human-readable, portable save format (JSON, not opaque binary `store_var`).
- **B2 — When the campaign save is written.** **[RESOLVED] Auto + manual.** Auto-save at
  key moments (map cleared, entering prep) so progress is never lost, PLUS a manual "Save"
  in the prep screen / pause menu to write to a chosen slot.
- **B3 — Suspend save (mid-battle).** **[RESOLVED] Persistent, re-loadable.** Suspend stays
  on disk and can be reloaded repeatedly (NOT consumed on resume). Consistent with B4's
  free-reload stance. Still the carrier for threat-range `_watch_set`/`_danger_mode` (slice 4).
- **B4 — Permadeath & save-scumming.** **[RESOLVED] Reloading always free.** No scum locks.
  Permadeath means defeated allies stay lost **only if the player doesn't reload**; the
  player may always reload any save (incl. suspend) to undo. Friendly stance, accepted.
- **B5 — Total defeat outcome.** **[RESOLVED] Multi-choice Game Over menu.** Options:
  (1) Reload most recent save, (2) Reload any save (slot picker), (3) Main Menu, and
  (4) a **hidden "Rewind Time"** option shown ONLY when the campaign's rewind rule is
  enabled — with a note of **charges remaining**, grayed out at 0 charges. → branch **J**.
- **B6 — Save/Load slot menu presentation.** **[RESOLVED]** Each slot row shows:
  **chapter/map name + progress** (turn # for a suspend), **playtime + last-saved timestamp**,
  a **party snapshot** (count / gold / lord), **ruleset badges** (permadeath / ironman /
  rewind charges), and a **player-editable label** (`save_label`) defaulting to the campaign
  name. Empty slots show "Empty". Used by both Load Game and manual Save-to-slot.

## C. Between-map prep / deployment  (depends on A3)
- **C1 — Prep screen presence.** **[RESOLVED] Always, between every map.** It's the hub
  (A3). MVP contents = deploy/bench + placement + manual Save + Begin Battle ONLY. Convoy
  (D) and Shop (E) are deferred to follow-on slices, NOT in the MVP prep screen.
- **C2 — Deployment model.** **[RESOLVED] Per-map required/excluded lists + player fill.**
  Each map's data can: (a) **require** specific characters to be deployed (forced, un-benchable
  — e.g. the lord/escortee), (b) mark specific characters **unavailable** for this map *if
  they exist in the roster* (story lockouts), and (c) the player fills the remaining
  deployment slots (up to the map's cap) with any eligible roster unit. Richer than a plain
  "lord locked" model — needs `required_units` + `excluded_units` + `deployment_cap` on map data.
- **C2b — Placement.** **[RESOLVED] Map-authored start tiles, player assigns.** Map defines
  deployment tiles; player assigns which deployed unit goes to which tile in prep (or auto-fill).
- **C3 — Benched units.** **[RESOLVED] Gain nothing; freely swappable.** No passive EXP/items;
  benched units persist in the roster and can be swapped in at the next prep.
- **C4 — Rule-dependent prep.** **[RESOLVED — empty for MVP]** Pair Up stays map-scoped
  (H1), Support/Rescue deferred (H2/H3) → no rule-dependent prep setup in the MVP prep screen.

## D. Convoy / inventory  (sub-branch of C) — **DEFERRED from MVP** (C1)
Not in the MVP prep screen; design later as a follow-on slice. Forward intent only so the
save schema reserves room: `party_items: Array[String]` already persists on `GameState`; a
future convoy is its richer form (quantities + a shared store + per-unit `max_inventory=8`
enforcement). D1/D2/D3 deferred. **Save-schema note:** keep item ownership representable as
"convoy store + per-unit inventory" so adding convoy later is data growth, not a reshape.

## E. Shop / economy  (sub-branch of C) — **DEFERRED from MVP** (C1)
Not in MVP. `party_gold` already persists. Forward intent: between-map buy/sell shop spending
`party_gold`; gold sourced from map rewards/selling. E1/E2/E3 deferred. **Save-schema note:**
`party_gold` stays the single economy field; shop is a later consumer.

## F. Recruit (green → player) — **DEFERRED from this cluster**
- **F1/F2 — [RESOLVED] Defer recruit entirely.** No interactive Talk/Recruit mechanic in
  this cluster. The roster grows only via map-authored "these units join now" grants (if any
  map authors one). The interactive recruit mechanic is a later milestone. **Save-schema
  note:** roster growth must already be supported (the save persists the full `player_roster`),
  so adding recruit later is data, not a reshape.

## G. Campaign-rules surfacing
- **G1 — Read active rules.** **[RESOLVED, soft] Read-only display in prep/pause.** Player
  cannot edit rules in game; a read-only "Campaign Rules" view in prep/pause lets them check
  what's active and why a rule-gated action is unavailable. (Low-stakes; kept as a rec.)
- **G2 — Rule mutability.** **[RESOLVED] Player-locked; STORY-flippable; tinkerer-warned.**
  Rules cannot be edited in-game by the player. They CAN be flipped by authored **story
  events** (a chapter/event hook may change a rule) — so the rules schema must allow scripted
  mutation at defined points, just not player UI. The save file's rules region carries an
  **extra inline warning for tinkerers** that hand-editing rules may **irreparably break the
  save**. (Reinforces branch I: human-readable save + inline warnings + validation.)
- **G3 — Story rule-flip notification.** **[RESOLVED] Explicit in-game notice.** When an
  authored story event flips a rule, show a clear notification ("Permadeath is now enabled…")
  so the change is never silent. The new value then reflects in the read-only rules view (G1).

## H. Pair Up / Support / Rescue — **ALL DEFERRED from this cluster**
- **H1 — [RESOLVED] Pair Up stays map-scoped.** Pairings continue to reset each map
  (`reset_map_state()` unchanged); they do NOT persist in the campaign save and there is no
  prep-time pairing management. C4 (rule-dependent prep) therefore drops to nothing for MVP.
- **H2 — [RESOLVED] Support deferred.** Not in this cluster.
- **H3 — [RESOLVED] Rescue deferred.** Not in this cluster. Pair-Up/Rescue exclusivity prior
  stands for whenever Rescue is designed.

## I. Modding / homebrew campaigns  (NEW — surfaced by B1)
Stated intent: users should be able to **author and distribute homebrew campaigns**, with
save export/import as the portability mechanism.
- **I1 — Scope in THIS cluster.** **[RESOLVED] Portable saves now, packs later.** Now:
  human-readable JSON save format + filesystem export/import + load-time validation. Keep
  campaign content data-driven (mod-friendly), but DEFER the formal distributable
  campaign-pack format & authoring tools to a later milestone. I2/I4 stay live for this
  cluster (save format + robustness); I3 (pack format) deferred but must not be blocked.
- **I2 — Save format.** **[RESOLVED, one tradeoff open] Human-readable JSON + inline
  warnings + format-version.** Pretty-printed JSON, a `format_version` field, and `_warning`
  string fields on dangerous regions (JSON has no real comments). Plus a player-editable
  **`save_label`** string defaulting to the campaign name (shown in the slot menu). **OPEN
  tradeoff (I2a):** the player wants export/import to move a save as a **single portable unit**
  across filesystems/OSes, possibly compressed — which slightly fights raw tinkerability.
  **Rec:** an MVP campaign save is small and already a single JSON file → export it as ONE
  `.json` (max tinkerability, zero bundling needed); reserve **zip-bundling/compression for
  the deferred campaign-PACK format (I3)** where multiple files/assets actually need
  bundling. (Confirm in I2a.)
- **I2a — Export form.** **[RESOLVED] Single `.json` now; importer sniffs zip-vs-json;
  zip-bundle deferred to packs.** Feasibility checked: Godot 4.6 ships `ZIPPacker`/`ZIPReader`
  in core → standard DEFLATE `.zip` that desktop tools (Explorer/Archive Utility/`unzip`/7-Zip)
  read, so a later bundle is easy and interoperable. Migrating single→multi is low-cost IF we
  (a) stamp `format_version` and (b) keep a serialize/deserialize seam (`SaveData` ↔ Dict)
  separate from file I/O — both required here. **Forward-compat hook built now:** the import
  path **sniffs the leading bytes** (`PK\x03\x04` = zip, `{` = raw JSON) and branches, so a
  future campaign-pack bundle imports with zero migration. The `user://` in-app save stays
  single-JSON; only a future *export* gains the zip wrapper. **Web caveat:** on the web build,
  filesystem export/import routes through the browser download/upload sandbox (true for any
  format), not arbitrary paths — a platform wrinkle, not a format decision.
- **I3 — Campaign-pack format.** **[DEFERRED]** Distributable campaign bundle (maps + roster
  + progression graph + rules) — design later. Likely the home for any zip-bundle/compression.
- **I5 — Cross-version save transfer.** **[RESOLVED — not a concern until 1.0]** Loading an
  older build's save in a newer game (or vice-versa) is **explicitly NOT a major concern
  before the 1.0 release**. Pre-1.0 we may break save compatibility freely between versions —
  do **not** invest in migration/back-compat code now. The cheap insurance we DO keep is the
  `format_version` stamp (I2) + the serialize/deserialize seam, so that *if* migration is
  wanted later it's possible — but writing migrations is out of scope until 1.0. Loaders may
  simply refuse (or warn-and-continue per I4) on a `format_version` they don't recognize.
- **I4 — Robustness / integrity.** **[RESOLVED] Integrity hash + tamper-aware warn-and-continue
  (NOT hard reject).** On **export**, attach an **integrity hash** computed over the save data.
  On **import/load**, recompute it: a mismatch raises a **warning** ("data was changed or
  corrupted") but the player MAY continue. Certain **author-defined protected fields** raise a
  **secondary, stronger warning** if specifically altered. The player **acknowledges
  responsibility** ("we may not parse this correctly; breakage is on you") and the game then
  **attempts** the load. Hard failure only when the file genuinely can't be parsed into the
  schema. This supersedes the earlier "validate + reject" lean — the homebrew goal favors
  warn-and-continue. **Implications:** save metadata carries the hash + a notion of
  author-marked protected fields; the load path is warn-gated, not reject-gated.

## J. Rewind / Turnwheel  (NEW — surfaced by B5)
A per-campaign optional "rewind time" feature with limited charges, surfaced on the defeat
menu (hidden when disabled, charge count shown, grayed at 0).
- **J1 — Scope in THIS cluster.** **[RESOLVED] Hooks now, mechanic later — reuse the
  existing RNG design.** This cluster adds: the per-campaign rewind RULE + charge count on
  `CampaignRules`, charge persistence in the save, and the defeat-menu entry (hidden when
  off / charge count / grey at 0). The actual rewind mechanic is **deferred to Package A
  (`RngService`)** per `rng_determinism_design_2026-06-11.md` — rewind can't hold until
  `RngService` lands (per code_review_2026-06-14b).
- **J2 — Rewind granularity.** **[RESOLVED by RNG-1/3] Per-committed-action Turnwheel.**
  `history_hash` advances on every committed non-undoable unit action; rewind steps back to
  an earlier committed-action checkpoint. Not per-turn, not map-start.
- **J3 — Charges.** **[RESOLVED by RNG-3] Per-map charge pool owned by `CampaignRules`,
  default 3–5, `0 = ironman/off`.** Refills each map. The defeat-menu "charges remaining" =
  this map's remaining pool. Configurable per campaign (the campaign rule sets the count).
- **J4 — In-battle access.** **[RESOLVED] Yes — primarily an in-battle Turnwheel.** The
  defeat-menu entry is one additional entry point; the main use is rewinding mid-battle. Both
  spend from the same per-map pool. (In-battle UI built with the mechanic in Package A.)

---

# Resolution Log
(Answers recorded here as we resolve each node, newest first.)

- **2026-06-21 — I2a resolved → player-facing firming COMPLETE (A–J).** Export = single
  `.json` now; importer sniffs zip-vs-json so a later campaign-pack bundle needs no migration;
  zip-bundle/compression deferred to the pack milestone. Godot 4.6 `ZIPPacker`/`ZIPReader`
  make standard interoperable zips trivial when needed. Doc status flipped to PASS COMPLETE.
- **2026-06-21 — Branches C/D/E/F/G/H/I/J resolved; MVP scope tight.** C prep = deploy/bench
  + map-authored required/excluded/cap + player-assigned placement + manual save + launch;
  benched gain nothing. D convoy / E shop DEFERRED (save reserves `party_items`/`party_gold`).
  F recruit DEFERRED (roster growth already save-supported). G rules player-locked +
  story-flippable + tinkerer-warned + explicit flip notification + read-only prep view.
  H Pair Up stays map-scoped; Support/Rescue deferred. I2 human-readable JSON + version +
  `_warning` fields + `save_label`; I4 integrity-hash + tamper-aware warn-and-continue (not
  hard reject); I3 pack format deferred. Slot menu (B6) shows chapter/playtime/party/badges/
  label. **One open: I2a** export-as-single-unit / compression tradeoff.

- **2026-06-21 — A4/B2/I1/J resolved; J folded into existing RNG design.** A4 Continue =
  resume most-recent activity; B2 auto + manual save; I1 portable saves now / packs later;
  J1 hooks now (rule + charges + defeat-menu entry), mechanic deferred to Package A
  `RngService`. J2/J3/J4 already locked by `rng_determinism_design_2026-06-11.md` RNG-1/2/3:
  per-committed-action Turnwheel, per-map charge pool on `CampaignRules` (default 3–5, 0 =
  ironman), in-battle + defeat-menu entry points. **Dependency:** rewind needs `RngService`.
- **2026-06-21 — Branch B (save model) resolved + 2 new branches opened.** B1 in-app slots
  + filesystem export/import (intent: homebrew campaign authoring/distribution → new branch
  I); B3 persistent re-loadable suspend; B4 reloading always free (no scum locks); B5
  multi-choice Game Over menu incl. hidden charge-gated Rewind option (→ new branch J).
  New branches I (modding/homebrew) and J (rewind/turnwheel) added. A4/B2 still mechanical-open.
- **2026-06-21 — Branch A (spine & scope) resolved.** A1 MVP spine first; A2 linear now but
  overworld-ready (progression-registry/graph node model, not a hardcoded chain — supports a
  later Awakening-style overworld with chapters/interludes/wandering encounters/side-quests);
  A3 between-map prep surface. A4 (Continue) deferred to branch B.
