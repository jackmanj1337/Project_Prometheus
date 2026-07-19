# GDD_07 — Screens And Panels

**Status:** Active surface contract — implemented, validation-pending, and planned
slices are labelled per section.
**Last verified:** 2026-07-19
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This companion owns the screen/panel catalog and each surface's player-facing behavior.
Cross-cutting navigation, feedback, and accessibility remain in
[GDD_07 — UI & UX](GDD_07_UI_UX.md); tactical input/cursor mechanics live in
[GDD_07 — Input And Cursor](GDD_07_Input_Cursor.md).

---

## Screens and Panels

Status: **Split** — MVP screens, the campaign Load Game picker, and the campaign
Prep/manual-save screen are **Implemented**; the V030-SUS-01 suspend Continue
restore fixes are **Pending validation** (fixed 2026-07-09, awaiting live rerun);
combat-animation feedback is **Planned**
Last verified: 2026-07-15

---

### Main Menu

**Scene:** `MainMenu.tscn`
**Trigger:** Game start / quit from map

**Layout (centered on 1280×720):**
```
┌─────────────────────────────────┐
│    [PLACEHOLDER — Game Title]   │
│                                 │
│         [ Continue ]     (greyed if there is no save to continue)
│         [ Load Game ]    (greyed if no campaign slot exists)
│         [ New Game ]            │
│         [ Settings ]            │
│         [ Quit ]                │
└─────────────────────────────────┘
```

**Behavior:**
- The home screen uses the Mana Soul theme and is a pinned-large surface: its panel
  fills the safe rectangle between title and version labels and ignores the tactical
  Menu Scale preference, preventing high-scale title overlap.
- "Continue" → resumes the **most recently written** slot. `SaveManager` has one
  namespace; after loading, `map_runtime.map_path` routes a mid-map document onto
  `GameState` + `GameMap`, while its absence routes a between-map document through
  campaign restore and launches the parked node. It is disabled when there is nothing to
  continue; load failure opens an error dialog and stays on Main Menu. A
  Completed slots are skipped, including fallback selection; with only completion
  records Continue is disabled while Load Game remains available.
  On suspend restore (V030-SUS-01, fixed 2026-07-09): units whose serialized state is
  DONE re-apply the darkened DONE appearance (so a spent unit reads as spent, not
  as an actable one it silently refuses); a paired support restored onto the
  off-map sentinel `(-1,-1)` stays hidden instead of drawing at the placeholder;
  and the restore emits `turn_changed` so the HUD turn counter reflects the
  restored turn immediately rather than after the next round boundary.
- "Load Game" → opens the `LoadGameScreen` overlay (see below). Disabled when
  `SaveManager.list_slots()` is empty, so a player with no campaign save sees the
  pre-campaign menu with Load greyed out.
- "New Game" → opens the `NewGameScreen` overlay
- "Settings" → opens Settings screen (see below); available from MVP onwards
- For MVP: "Continue", "New Game", "Settings", and "Quit" are functional

---

### Load Game Screen

**Scene:** `LoadGameScreen.tscn`
**Trigger:** "Load Game" from the Main Menu
Status: **Implemented 2026-07-14** (`B1-CST` Slice 3)
Last verified: 2026-07-15

A modal overlay child of Main Menu (`open()` / hide, no scene change), listing the
written slots of either intrinsic kind. It loads, deletes, and transfers existing
saves. Prep writes fresh manual campaign progress as a *between-map* action through
`CampaignManager.write_campaign_slot` (`B4-PREP-DEPLOYMENT`). Map Menu writes
the reserved mid-map `resume_battle` slot through the same store.

**Behavior:**
- One row per slot, from `SaveManager.list_slots()`: `Resume battle — Turn N` for
  a mid-map row or `Continue — node` for a between-map row, plus the save's label,
  party size, gold, and save time. Every field is
  mirrored into the saves index at write time, so drawing the list never opens or
  validates N save files.
- Rows are **newest first**, ordered by a monotonic `write_seq` rather than the
  timestamp (`saved_at_unix` has whole-second resolution, so two saves written in
  the same second would tie). The timestamp is display only.
- Manual writes obey the campaign's first compatible `save_slot_classes` entry;
  a full class refuses a new id but still permits replacing one of its existing
  manual rows. `consumed_on_load` removes a row only after restore and scene
  routing succeed. Autosave rows live outside those counts and rotate only within
  their own `origin:auto` + `rule_id` pool.
- An `origin:auto` save — written by the campaign flow on node commit today — is
  a normal row, marked `[Autosave]` so the player can tell apart the save that
  gets overwritten under them from one they wrote themselves.
- A terminal autosave remains visible as a `[Completed]` campaign completion
  record. Its row shows campaign-complete details and is not activatable, so it
  is retained for future continuity/NG+ export without attempting an empty node.
- Activating a row runs the **same restore path as Continue** (stage onto
  `GameState`, then `CampaignManager.launch_current_node()`), so the two cannot
  drift apart. A slot that fails to load (corrupt or version-mismatched) opens the
  same error dialog Continue uses and stages nothing.
- Each row offers **Delete** behind a confirmation. Deleting the slot Continue
  pointed at also clears that pointer, so Continue falls back to whatever is still
  on disk, or disables when nothing is.
- A row whose save file has vanished is skipped by `list_slots`, so the picker can
  never offer a save it cannot load.
- Each row offers **Export** to a filesystem FileDialog. The result is one
  human-readable `.json` document with canonical whole-payload and protected
  campaign/progression SHA-256 stamps. **Import Save** sniffs ZIP versus JSON,
  routes campaign-package ZIPs to New Game's Manage Campaigns surface, validates
  JSON saves, and writes an available `imported_NN` slot. A changed payload shows
  an explicit warning; protected-field changes add a stronger warning, and the
  player must choose **Import Anyway** before the warn-and-continue path writes.
- Back returns to the Main Menu without reloading the scene.

Between-map slot loads route to the implemented Prep screen through
`CampaignManager.launch_current_node`; mid-map rows restore directly into GameMap.

---

### New Game Screen

**Scene:** `NewGameScreen.tscn`
**Trigger:** "New Game" from the Main Menu

The live new-game flow is no longer a direct jump into `Map 001`. It is a modal
setup screen that writes per-run rules onto `GameState.campaign_rules`, then
launches a shipped, generated one-map, or installed campaign through one prep path.

**Current options:**
- `Campaign` — authored campaigns plus one generated one-node campaign per map
  registry entry. Installed rows show campaign label plus exact pack id/version;
  `is_dev_only` rows are excluded outside debug builds.
- `Permadeath` — Off / On
- `Auto Promote` — Off / On
- `Leveling` — Random / Fixed
- `Pair Up` — Off / On
- `Carry Forward` — None or a compatible checksummed CampaignStatusRecord

**Behavior:**
- Every row calls `CampaignManager.start_campaign()` and
  `launch_current_node()`. Authored runs enter their first node; generated rows
  enter their sole map node. There is no direct-map bypass.
- An installed row activates its exact Tier-2 `{package_id, package_version}`
  through `DataManager` before `CampaignManager.start_campaign()`. A failed
  activation stays on New Game with the prior source intact. Choosing a shipped
  row after an installed campaign restores `res://data` first.
- Selector refresh always composes installed summaries with an immutable shipped
  catalogue snapshot; activating a package cannot hide or duplicate shipped
  campaigns. The selector remains the gateway to future campaign-owned start menus,
  where authored progression policy decides whether players choose a start node.
- The rule toggles (`Permadeath`, `Auto Promote`, `Leveling`, `Pair Up`) write through
  to `GameState.campaign_rules` the moment they change, so closing the panel with Back and reopening
  it remembers the choices — Start is not required to persist them.
- Campaign-authored rule rows seed each control. An `authority: mandate` row is
  visibly disabled and cannot be overwritten; an `authority: default` row seeds
  an editable choice. This authority list persists with the save.
- Selection defaults to the first still-installed identity in this order:
  `last_started`, then `last_imported`, then the deterministic first row. Starting
  records exact `{campaign_id, package_id, package_version}`; successful import
  records the first non-dev campaign in the imported pack without activating it.
- Selecting a campaign scans the status-record store for same-campaign or
  author-declared compatible sources. **None** remains the default clean start.
  **Import Status Record** validates a foreign JSON/checksum through an explicit
  manual path and labels it separately. The chosen record is applied only after
  campaign start succeeds; failure ends the staged run without partial facts.
- Back returns to the Main Menu without reloading the scene
- **Manage Campaigns** opens a modal package library. Import chooses a ZIP from
  the filesystem, displays structured validation or optional-asset repair
  feedback, installs without activating it, and refreshes the Run selector.
  Export chooses an installed `{package_id, version}` and a filesystem
  destination, then writes a deterministic re-preflighted ZIP.
- Printable gameplay bindings yield to a focused editable text field. Mirrored
  Confirm/Cancel keys such as Z/X type into filesystem FileDialog names instead of
  validating or closing the dialog on the first press.

This screen is onboarding-relevant because every map-registry entry now reaches
the same campaign/prep/save lifecycle as authored multi-map content.

### Prep, Service, And Authoring Panels

Status: **Split** — campaign deployment and manual save are **Implemented
2026-07-15**; registered service panels are **Target design**
Last verified: 2026-07-19

**Scene:** `PrepScreen.tscn`
**Trigger:** launching or retrying a campaign node

Prep is a full destination screen, not a modal. It lists every living,
non-excluded party member; required units are selected and locked. Deploy toggles
choose the fighting party up to the node/map limit, and Up/Down orders each unit
onto the numbered `MapData.player_start_tiles`. Begin Battle stays disabled until
`DeploymentPlan.validate` accepts the plan, then stages it on `GameState` and
enters `GameMap` without reapplying roster policy.

Above deployment, Prep shows the effective campaign rules as a read-only summary;
mandated values carry a locked marker. On-map story flips raise a transient
notification with the changed rule, new value, authored reason, and whether the
change lasts for this map or the campaign.

Every campaign launch parks here. Campaign Retry first restores ledger entry 0,
then returns here with the previous deployment preselected; bare-map and
suspend-resumed retries retain direct map reload. The screen also writes manual
campaign saves through `CampaignManager.write_campaign_slot`. Slot ids are
player-supplied filenames, so invalid ids are rejected rather than sanitized;
the optional label is display-only and successful slots appear in Load Game.

Prep services and on-map services use the shared PHB panel model. Shops, convoy,
training, arena, villages, object activation panels, and future side activities should
register panel/activity ids and data schemas; the UI opens the registered panel with an
actor/context instead of branching on a closed panel enum.

The public builder/authoring GUI is deferred (`B8-PUBLIC-BUILDER`). Until then, the
portfolio path is data-only authoring through resources/manifests plus a slice-first web
demo. Any later public scripting UI is bounded by the sandbox ceiling from SET-013.

---

### In-Map HUD (persistent overlay)

The HUD is always visible during a map. It uses a `CanvasLayer` so it is unaffected
by camera movement.

**Layout:**

```
┌──────────────────────────────────────────────────────┐  ← top of screen
│ Phase Label (top-left)           Turn Label (top-right)│
│ e.g. "Blue Phase"                e.g. "Turn  3"        │
└──────────────────────────────────────────────────────┘

              [MAP VIEW — tiles, units, cursor]

┌──────────────────────┐               ┌────────────────┐
│ UNIT INFO PANEL       │               │ TERRAIN PANEL  │
│ [Portrait] Name       │               │ Forest         │
│            Class      │               │ DEF    +1      │
│            HP 17/21   │               │ Dodge  +15     │
│            Iron Lance │               └────────────────┘
└──────────────────────┘
  ↑ bottom-left                           ↑ bottom-right
```

**Unit Info Panel** (`UnitInfoPanel.tscn`):
- Shown when cursor hovers over any unit (ally or enemy)
- Hidden when cursor is on an empty tile with no unit
- Size: ~300 × 110 px
- Portrait: [PLACEHOLDER] 64×64 px class portrait
- For a paired **lead**, a `Support: <name>` line names the off-map partner so the
  player can see who they paired with without opening the character sheet (V020-09).
  **V021-07:** the per-stat `Paired +N Str +N Def …` deltas were removed from the
  *map* HUD — they crowded the bottom-left panel and pushed the support name off the
  screen edge; the full per-stat breakdown lives on the `I` character sheet (via
  `StatContributions`). The default `UnitInfoPanel` position was also raised so the
  block has headroom for its lines on the 720-tall reference viewport. Supports are
  off-map and never displayed as the panel's own hovered unit.
- On the map, a visible paired lead shows a small `PU` badge on the unit sprite.
  The marker is driven by `PairUpRegistry.pair_up_changed`, so Pair Up, Swap,
  Separate, clear, and snapshot restore all refresh the badge without polling.

**Terrain Info Panel** (`TerrainInfoPanel.tscn`):
- Always shown (updates as cursor moves)
- Shows terrain name, DEF bonus, Dodge bonus
- In the current build it also hosts the phase-1 More Info terrain text:
  description, move-cost notes, and available tile actions
- Size: ~180 × 80 px

**Objective Panel:**
- Lists the active blue-group win/lose conditions from authored `ObjectiveCondition`
  resources
- Tile coordinates shown in objective text are player-facing one-based coordinates;
  the underlying objective data and evaluator stay zero-based.
- Hidden on maps that do not author objective text for the current view

**Phase Label:**
- Text is faction-driven, not hardcoded player/enemy text
- Uses `Faction - Controller` text from one shared formatter, for example
  `Blue - Player 1`, `Red - AI`, or `Green - Player 2`
- Updates on phase change; fades in briefly after banner

**Turn Label:**
- Text: "Turn  3"
- Increments when the scheduler wraps back to blue in whole-phase maps

---

### Phase Banner

**Scene:** `PhaseBanner.tscn`
**Trigger:** Each phase change

**Layout:**
```
[full-width colored bar slides in from right, pauses, slides out to left]
┌────────────────────────────────────────┐
│            BLUE PHASE                  │   ← example; display text is authored
└────────────────────────────────────────┘
```

**Animation (Tween):**
1. Banner starts off-screen right (x = 1280)
2. Slides to center (x = 0) over 0.3 seconds
3. Holds for 0.8 seconds
4. Slides off-screen left (x = -1280) over 0.3 seconds
5. `cursor.unlock()` called after animation completes

Colors:
- Driven from `FactionData.color` for the acting faction
- Text uses the faction's authored display name

Font size: 40px, bold [PLACEHOLDER font]

---

### Action Menu

**Scene:** `ActionMenu.tscn`
**Trigger:** After a controllable unit successfully moves (or confirms on its current tile)

**Layout (positioned near the moved unit, offset to avoid covering it):** anchored to
the unit tile's **far edge plus a constant 4px gap** (`MapCursor._place_menu_near`,
V027-02) — the tile-width term scales with map zoom but the gap does not, the same
model the Attack Preview uses, so the menu hugs the unit without covering it at any
zoom. Flips to the left side when the right doesn't fit; keeps its side across zoom
repositions (V025-03 stickiness).
```
┌────────────┐
│  Attack    │
│  Staff     │
│  Item      │
│  Equip     │
│  Seize     │
│  Escape    │
│  Pair Up   │
│  Swap      │
│  Separate  │
│  Wait      │
└────────────┘
```

The menu is **contextual**. Unavailable actions are hidden entirely rather than shown
disabled, so the visible row set depends on the acting unit, tile, and current map.
Its 128px design width is a floor: at larger Menu Scale values the panel expands
to the widest visible label plus a font-scale-aware safe area for the inward
ornaments. Each population pass shrink-wraps both rendered axes so a previous
tall or wide action list cannot leave stale panel space.

**Behavior:**
- Menu appears adjacent to the unit's new tile; repositioned if too close to screen edge.
  The tile anchor is remembered while the menu is open, so map zoom or the Settings
  Map Zoom slider re-place the contextual Action/Item/Weapon menu against the same tile
  instead of leaving it at a stale screen position (V023-03).
- Navigate with `cursor_up` / `cursor_down` (wraps, skipping disabled buttons);
  confirm with `confirm`; close with `cancel`
- Closing with cancel triggers undo: unit returns to its pre-move tile
- `Seize` / `Escape` are gated by shared `TileActions` logic so the action menu and
  terrain More Info panel agree
- `Pair Up`, `Swap`, and `Separate` are shown only when the pairing state allows them

**Button widths:** 120 px; height per button: 30 px
**Font size:** 18px

---

### Target Selection

**Trigger:** Player selects "Attack" or "Staff" from the Action Menu.
**Owner:** `MapCursorTargeting` (a `RefCounted` slice of `MapCursor`).

There is **no target-list panel**. Target selection happens on the map itself:

- The valid target tiles are highlighted with overlay tiles — **red** for Attack
  targets, **green** for Staff (heal) targets.
- The cursor snaps to the first valid target. Direction keys, d-pad directions,
  and the left stick **cycle** the cursor between valid target tiles (the list wraps).
  With `Mouse Cursor = Follow`, mouse motion snaps the cursor to the nearest valid
  target; `Click` waits for a click/tap to move, and `Off` (`disabled`) ignores mouse motion.
- `confirm` on an Attack target opens the Attack Preview; `confirm` on a Staff target
  applies the heal immediately. `cancel` returns to the Action Menu.

---

### Attack Preview Panel

**Scene:** `AttackPreview.tscn`
**Trigger:** Player confirms an attack target during on-map target selection

**Layout (anchored near the defender on screen rather than fixed to the bottom):**
```
┌────────────────────────────────────────────────┐
│   [Attacker Name]          [Defender Name]     │
│   Hit:   82%               Hit:   55%          │
│   Dmg:    7                Dmg:    4            │
│   Crit:   5%               Crit:   0%           │
│   ×2 attacks               ×1 attack            │
│                                                │
│             [Z/Enter = Confirm]                │
│             [X/Esc   = Cancel ]                │
└────────────────────────────────────────────────┘
```

**Rules:**
- If the defender cannot counterattack (out of range, or no weapon):
  the defender side collapses to a `No counter` readout and omits the normal
  hit/crit rows
- If attacker gets a follow-up, show `×2 attacks` below their crit
- Preview calls `ProjectionService.project_combat()`, whose combat adapter delegates
  to `CombatResolver.preview_combat()` — no committed RNG or live-state mutation
- A failed projection clears the prior More Info selection list, so stale forecast
  rows cannot remain navigable after the preview becomes invalid
- Confirm triggers `CombatResolver.resolve_combat()` (with RNG)
- The current panel also shows weapon-triangle and effectiveness markers
- A **weapon row** under each combatant's name shows the equipped weapon's display
  name ("Unarmed" when none), so matchups read at a glance without opening the sheet
  (V021-14). It's a plain readout, not a selectable More Info field. These rows are
  measured with the rest of the forecast rows so exported builds cannot collapse them
  to zero height (V023-04).
- Neutral weapon-triangle/effectiveness states render a low-emphasis gray `Neutral`
  marker instead of a blank cycle-only row (V023-04).
- Phase-1 More Info adds an info box on the right; `more_info` cycles through each
  preview field and clicking a field opens its description. The info text is a bounded
  scroll area with enough vertical fill to avoid clipping longer descriptions at large
  display/zoom settings (V023-04).
- The **Damage** field's More Info also shows each side's **Battle Speed** and the
  follow-up threshold (and who, if anyone, doubles) — the values needed to verify
  the follow-up math (handbook 8.3). `preview_combat()` returns
  `attacker_battle_speed` / `defender_battle_speed` / `follow_up_threshold`.
  Both sides' Battle Speed are shown **even when the defender cannot counter**
  (playtest v0.1.5.0 #8.3): the defender's speed is still informative and the
  attacker can double a non-countering defender, so the note reads
  `Attacker N vs Defender M … (defender cannot counter)` rather than hiding the
  defender's value.

**Size:** Content-sized three-column layout, clamped/repositioned to the viewport.
On every show, sizing + placement re-run once one frame later with the panel held
transparent (V027-03a): RichTextLabel content minimums read inflated until a layout
frame passes, which used to freeze dead space under the rows on the first open.
**Placement:** Anchored beside the defender (right, else left), kept inside the viewport,
and nudged clear of the visible HUD panels (objective / unit-info / terrain corners)
and the defender tile so it does not cover them (`AttackPreview._place_clear_of`).
Avoidance is best-effort: a panel too tall to clear an avoid rect is left clamped
on-screen rather than pushed off. Placement always reads a **settled canvas
transform**: every camera write callers read synchronously — including cursor-driven
scrolls (`keep_cursor_in_view`, V027-03b) — flushes via `force_update_scroll`
(V026-03/04a), and the zoom-reposition hook re-runs once one frame later (coalesced)
as a self-heal for anything that lands after it.
**Font size:** 18px

---

### Staff Use

**Trigger:** Player selects "Staff" from the Action Menu — enabled only when the unit
has a healing staff equipped and at least one injured ally in range.

Staff targeting uses the same green-overlay + cursor-cycling flow as attack targeting
(see Target Selection). Confirming on an ally heals them for `10 + MAG` HP via
`Unit.perform_staff_heal()`, awards the healer EXP and wEXP, and ends the unit's
turn. There is no separate staff-preview panel in MVP.

---

### Item Menu

**Trigger:** Player selects "Item" from Action Menu
**Layout:** Same style as Action Menu; lists inventory items with uses remaining

```
┌──────────────────────┐
│  Vulnerary    (3)    │
│  Elixir       (3)    │
└──────────────────────┘
```

- Selecting an item and confirming uses it (healing items restore HP immediately)
- Ends the unit's turn after use
- Cancel returns to Action Menu

---

### Unit Details Screen

**Scene:** `UnitDetailsScreen.tscn`
**Trigger:** `inspect_unit` while the cursor is over a unit

This is the live character-sheet overlay. It shows:

- unit name, class, level, internal level (labelled `Internal Lv`, not `Int`), and EXP
- a compact **class summary** section (V020-11): the title uses `ClassData.display_name`,
  and a selectable class row shows just **name + tier** (V021-10). Selecting it opens the
  full class detail in the More Info side panel: `ClassData.description`, the resolved
  **Movement** type (V021-11), non-movement **Traits**, allowed weapon families, and
  class-skill unlocks. (The relocation keeps the inline row uncluttered and gives the
  movement type its own line instead of burying movement tags under Traits.)
- full core stat block using the effective display totals, with a final utility-stat
  row for **Constitution (`Con`)** and **Line of Sight (`LoS`)** — both intentionally
  uncapped, so their breakdown shows class cap "—" (V020-15)
- inventory with remaining uses
- equipped skills
- weapon ranks / WEXP progress
- a `View Support` / `View Lead` button when the inspected unit is paired, letting
  the player inspect the hidden support unit without leaving the sheet

The screen is read-only. It exists for inspection, not inventory management.
The main sheet column lives inside a fixed, centered scroll frame, so Menu Scale keeps
the modal centered while overflow content remains reachable at large factors (V023-02a).

**More Info integration:**
- every class, stat, inventory entry, skill, and weapon-rank row is selectable
- selection is driven three ways (V020-10): clicking a row, the cursor keys / d-pad
  (handled in `_input` before GUI focus navigation so arrows don't move button focus),
  or `more_info` (F) forward cycling; the selected row is marked with a `▶` highlight
- the cursor keys follow the on-screen grid (V021-06): each entry records its visual
  `(row, col)` during build (the stat block is two columns per row; skills share one
  row), so **Up/Down** move to the nearest entry one row away (matching column) and
  **Left/Right** step through the flat reading order. The earlier mapping pointed both
  Up and Left at the same backward step, so Up/Down read as Left/Right across the grid.
- the selection model is backed by `SelectionCursor`, shared UI navigation logic that
  supports sparse visual rows. The sheet adds a terminal `Back` control zone (V026-02e):
  moving down past the last content row focuses `Back`, and `confirm` closes the sheet.
  This keeps Back reachable by keyboard/gamepad even though the sheet consumes cursor
  directions before Godot focus navigation.
- the `View Support` / `View Lead` button is likewise a selectable **pair** control
  entry when a partner exists (V031-GP-05, 2026-07-12): traversal visits it just
  before `Back`, focusing the button, and `confirm` activates it — previously it was
  reachable only by mouse or the `next_unit`/`prev_unit` pair-jump shortcut, which the
  v0.3.1 tester read as the focus selector "skipping" it. The pair-jump shortcut stays.
- selection drives the scroll (V031-GP-05): the custom selector moves a text highlight,
  not GUI focus, so `follow_focus` alone never fired for content rows — on each
  selection change the sheet scrolls the owning section label into view
  (`ensure_control_visible`), and the control entries scroll via their real focus grab.
- description prose scrolls independently with Page Up/Page Down, right-stick
  vertical, or mouse wheel. Its hint appears only for overflow; entry changes reset it.
- all three More-Info surfaces route navigation through this one `SelectionCursor` core
  (B6-INPUT selector adoption): the character sheet (2-D grid), the combat forecast
  (`AttackPreview`, 1-D forward cycle), and the terrain pager (`HUD`, with the -1 = Hidden
  inactive stop). One core = one place the gamepad d-pad wiring attaches. Pure refactor —
  navigation behaviour on each surface is unchanged.
- stat entries show authored description text plus the full stat breakdown
- inventory **weapon** entries show their full stat block in the side panel —
  Mt/Hit/Crit, Wt, range (resolved against the inspected unit), required rank +
  family, uses, and effect tags (V020-10); item entries show their authored
  description
- the compact stat rows use the same `effective_display` value as the More Info
  breakdown, including Pair Up and other combat-only stat contributions

**Stat breakdown (per selected stat):**
- **Personal base / Class base** — the stored stat split into the unit's own value
  and the current class's base contribution (`personal_base = stored − class base`,
  clamped at 0 for authored units that store a stat below their class base).
- **Class cap** — the class's ceiling from `ClassData.stat_caps`. Stats outside
  `STAT_KEYS` (MOV/CON/LoS) are intentionally uncapped and show "—"; a `STAT_KEYS`
  stat with no authored cap shows a loud **`NO_CAP_DEFINED`** (a data-integrity
  signal — guarded by `test_class_stat_caps.gd`, so it should never appear in a
  shipped build).
- **Effective** — the displayed total including combat-only bonuses; rendered
  **green** when an active bonus raises it above base, **red** when a net debuff
  lowers it below base, plain otherwise.
- **Bonuses** — every active bonus with amount + source. Persistent sources
  (items/tonics) come from `active_modifiers`; **combat-only sources (Pair Up, the
  unit's own stat skills) are computed by `StatContributions`**, because they are
  stamped only at combat start (`duration_type="combat"`) and never live in
  `active_modifiers` outside a fight. `StatContributions` is the single authority
  the combat path also resolves through, and `test_stat_contributions.gd` is a
  drift guard asserting the sheet and combat report identical numbers. Each bonus's
  duration is shown by **scope label** drawn from the fixed V021-09 vocabulary
  (`GameConstants.VALID_DURATION_TYPES`, rendered by `StatBreakdown.format_duration`):
  `this_combat` → "this combat", `until_separated` → "until separated" (Pair Up),
  `until_unequipped` → "until unequipped", `until_end_of_map` → "until end of map",
  `x_turns` → "N turns", `permanent` → "—" (always-on stat skills). **The label is
  distinct from the lifecycle tick point.** A real `active_modifier` still carries its
  own `duration_type` for *when it decrements/clears* (`turn` per faction phase,
  `map_turn` per round, `combat` cleared at end of combat, `permanent` never) — Pair
  Up, for instance, is stamped `combat` (recomputed each fight) yet displays "until
  separated". `format_duration` accepts both the vocabulary and the legacy lifecycle
  types and maps each to the same wording; scope labels are matched before the
  negative-remaining "—" fallback so their `-1` sentinel isn't swallowed. M8
  conditions / M9 procs author against this vocabulary so they never reintroduce an
  ad-hoc string. (Aura skills are M9 stubs that target hit/dodge/crit, not base
  stats, so they contribute nothing here yet.)

This closes the v0.1.5.0 #8.5 surface gap: the Pair Up bonus now appears on the
compact character sheet, the detailed stat breakdown, the HUD unit-info panel, and
the paired lead's map badge.

This screen is one of the primary onboarding-relevant UI surfaces because it exposes
the runtime meaning of modifiers, skills, and WEXP without opening the code.

---

### Level Up Screen

**Scene:** `LevelUpScreen.tscn`
**Trigger:** Unit reaches 100 EXP and levels up

**Layout (centered panel, blocks all input until dismissed):**
```
┌────────────────────────────────┐
│   Elan leveled up!  Lv 4 → 5  │
│                                │
│   HP    21  →  22   ▲          │
│   STR    7  →   7              │
│   MAG    0  →   0              │
│   DEF    6  →   7   ▲          │
│   RES    3  →   3              │
│   SKL    6  →   7   ▲          │
│   SPD    6  →   6              │
│   LUK    6  →   7   ▲          │
│                                │
│         [Press Z]              │
└────────────────────────────────┘
```

**Behavior:**
- Stats that increased are shown with a `▲` marker and highlighted in yellow
- Stats that did not increase are shown in white
- Player presses `confirm`/`cancel`, or left/right-clicks, to dismiss. Wheel and zoom
  input are consumed while the popup is visible and do not dismiss it (V023-05).
- If multiple level-ups occur at once (EXP overflow), show one screen per level
- After dismissal, combat or turn resolution continues

---

### Map Menu

**Scene:** `MapMenu.tscn`
**Trigger:** `open_menu` action on an empty tile, or dedicated menu key

**Layout (centered overlay on top of map; map still visible behind):**
```
┌──────────────────┐
│   End Turn       │
│   Rewind (N)      │
│   Settings       │
│   Suspend & Quit │
│   Quit to Menu   │
│   Close          │
└──────────────────┘
```

**Behavior:**
- `End Turn`: calls `TurnManager.end_player_phase()`. If any unit has not acted,
  a confirmation prompt is shown first; if every unit is already done it ends
  immediately. (Note: the phase also ends automatically once the last unit acts.)
- `Rewind (N)`: shows the remaining per-map charges and is disabled when no
  earlier activation or charge remains. Activating it opens a compact retained
  history selector. Rows name the activated unit, show `(start x,y) → (end x,y)`
  to disambiguate matching units, and show charge cost. Choosing a row restores
  the boundary before that activation through the active-map resume path and
  reloads the tactical scene; it does not reroll identical decisions.
- `Settings`: opens the Settings screen (see below); the cursor stays locked
  while it is open. Settings is also reachable directly via the `open_settings`
  key (O) during a map.
- `Suspend & Quit`: captures immediately when the cursor opened the menu from a
  free, unsuppressed committed-action boundary controlled by a **local human faction**
  (blue, an authored hotseat faction, or the F9 hotseat override). During an
  AI-controlled phase the menu is restricted (End Turn and Rewind are disabled)
  and this command queues one request after explaining that the current AI action
  will finish first. It writes only at the next atomic activation boundary. It
  confirms, writes the normal named
  slot `resume_battle` (including the whole rewind ledger) through `SaveManager`, then returns to
  `Boot.tscn`; if the write fails, a failure dialog keeps the player on the map.
  A resumed non-blue local phase re-enters `HotseatController` after map/UI state
  restoration, retargeting and unlocking the cursor for the restored faction.
  A resumed AI boundary re-enters the same faction without replaying phase-start
  effects and skips units already serialized as `DONE`.
- `Quit to Menu`: returns to `Boot.tscn` after confirmation and clears map-scoped
  runtime state through `GameState.reset_map_state()`
- `Close`: closes the map menu and returns to the map.
- `cancel` also closes the map menu.
- A **left-click on the backdrop** (anywhere outside the centered panel) dismisses
  the menu (V021-13), matching common modal behaviour — handled via the menu's
  full-rect `gui_input`.

---

### Settings Screen

**Scene:** `SettingsScreen.tscn`
**Trigger:** "Settings" button in Main Menu or Map Menu, or the `open_settings`
key (O) during a map
**Script:** `scripts/ui/SettingsScreen.gd`

The Settings screen is a single panel — **not tabbed**. A full-rect opaque
`Dimmer` behind the panel makes it modal (the screen behind is fully hidden).
The panel's contents live in a `ScrollContainer` so the list never overflows.
Focus stepping keeps up to three row heights of lookahead context visible past
the focused row, capped below half the viewport at large Menu Scale values
(V032-D2, 2026-07-13). A focused leaf such as a slider resolves to its owning
visual list row, and the margin sums up to three visible sibling rows in the
direction of travel. Deferred requests are coalesced, and the newest request
changes the absolute scroll target only when that context lies outside the
viewport. The lookahead path is the sole scroll owner on Settings and Unit
Details, preserving mixed-height context without competing with
`ScrollContainer.follow_focus` or jumping between list ends (V034-UI-02).
It is an overlay opened with `open()` and dismissed by the `Back` button or the
`cancel` action. Each
control writes its change to `SettingsManager` immediately (volume via `set_volume()`,
which persists; option changes call `SettingsManager.save()`), so there is no separate
save-or-discard step.

All settings persist between sessions in `user://settings.cfg` (Godot's `ConfigFile`).
See GDD_01 → SettingsManager.

#### Layout (single VBox panel)

```
┌──────────────────────────────────────────────────┐
│                   Settings                       │
│                                                   │
│   Master   [━━━━━━━━━━━━━━━━━━━━]   80            │
│   Music    [━━━━━━━━━━━━━━━━━━━━]   70            │
│   SFX      [━━━━━━━━━━━━━━━━━━━━]   90            │
│   ─────────────────────────────────────────       │
│   Movement Speed     [ Normal ▾ ]                 │
│   Phase Banner       [ Show ▾ ]                   │
│   Level Up Screen    [ Show ▾ ]                   │
│   Mouse Cursor       [ Follow ▾ ]                 │
│   Auto End Turn      [ On ▾ ]                     │
│   Camera Edge Buffer [━━●━━━━] 2                  │
│   Map Zoom           [━━●━━━━] 1.0x               │
│   Menu Scale         [━━●━━━━] 1.0x               │
│   Terrain Dim        [●━━━━━━] 0%                 │
│   ─────────────────────────────────────────       │
│   Controls                                        │
│   Move Up               W / Up                    │
│   Confirm               Z / Enter / Space         │
│   ... (one row per game action — editable)         │
│   ─────────────────────────────────────────       │
│                   [ Back ]                        │
└──────────────────────────────────────────────────┘
```

---

#### Audio

Three `HSlider` controls — `Master`, `Music`, `SFX` — range 0–100, step 1. Dragging a
slider updates the matching audio bus in real time and saves immediately. Buses are
looked up by name (`Master` / `Music` / `SFX`); a missing bus is silently skipped.

| Setting | Default | Range |
|---|---|---|
| `master_volume` | 80 | 0–100 |
| `music_volume` | 70 | 0–100 |
| `sfx_volume` | 90 | 0–100 |

#### Gameplay options

Each is an `OptionButton`; selecting an option saves immediately.

**Movement Speed** (`movement_speed`, default `"normal"`) — how fast unit sprites
travel. `Unit.move_along_path()` reads it via `SettingsManager.get_movement_speed_seconds()`.

| Option | Per-tile duration |
|---|---|
| Normal | 0.12 s |
| Fast | 0.06 s |
| Instant | 0 s — `snap_to_tile()`, no tween (the `unit_moved` signal still fires) |

**Phase Banner** (`phase_banner`, default `"show"`) — `Show` plays the full
slide-in / hold / slide-out banner; `Skip` suppresses it (the HUD phase label still
updates).

**Level Up Screen** (`level_up_screen`, default `"show"`) — `Show` waits for a
`confirm` press; `Auto` auto-dismisses after ~1.5 s; `Skip` shows only a brief pop-up.

**Mouse Cursor** (`mouse_cursor`, default `follow`) — fixed vocabulary:
`follow`, `click`, `disabled` (V021-17; enforced by DOC-011
`check_docs.py`). `Follow` lets mouse motion drive the on-map cursor (in
`FREE` / `UNIT_SELECTED` it follows the pointer; in `TARGETING` it snaps to the
nearest valid target). `Click` makes hover inert: the first left-click/tap moves
the cursor to that tile, and a second left-click/tap on the same tile confirms.
In click mode, clicking the terrain panel cycles More Info pages
Hidden → Description → Movement → Hidden. `Off` (`"disabled"`) ignores mouse
motion entirely in every state, so stray bumps cannot nudge the cursor during
keyboard play (PT4 #1). Right-click/cancel and the middle-click threat resolver
(see *Threat Overlay*) stay intentional mouse actions. Legacy values still load: `"enabled"` → `"follow"`;
old `mouse_targeting="snap"` → `"click"`.

**Auto End Turn** (`auto_end_turn`, default `true`) — when On, the acting human
phase commits automatically after every controllable unit is `DONE`.

**Camera Edge Buffer** (`camera_edge_buffer`, default `2`, range `0-5`) — number
of tiles from the viewport edge that trigger camera panning. The value is
clamped when loaded from the settings file.

#### Controls (editable)

A **Controls** section lists every game action and the bindings read live from the
`InputMap` when the screen opens (`_populate_keybindings()` builds one row per action).
Normal game-action rows expose keyboard/mouse and gamepad capture buttons; debug-only rows
stay read-only. Captures are staged in a pending buffer and do not touch the live
`InputMap` until **Apply**. A same-slot conflict marks both rows red and disables Apply;
each conflicting row exposes **Clear**, which leaves that device slot unbound. **Revert**
discards pending edits, and **Reset Controls** is always visible.

`SettingsManager` persists the backing model under `[controls].profiles`: the active
`"Default"` profile maps each action to `{"kbd": token, "pad": token}` using
hand-editable strings (`Z`, `Mouse1`, `JoyA`, `JoyAxis5+`). Old `Object(InputEvent...)`
cfg blobs migrate into that profile shape.

The **Input Prompts** dropdown (`input_mode`, default `auto`) exposes the fixed
vocabulary `auto`, `gamepad`, `touch`, `mouse_keyboard` (enforced by DOC-011
`check_docs.py`). The visible label is deliberately prompt-focused: the setting
changes prompts and focus defaults, not which physical devices are allowed. It
is a **gray-state selector**: modes unsupported on the current platform (e.g.
`touch` on desktop) are shown **disabled**, not hidden, so the vocabulary stays
visible and self-documenting. The chosen value is the persisted preference;
`InputModeManager` resolves the runtime `active_input_mode`, emits
`input_mode_changed`, records the last joypad device that sent real input for
brand-aware prompts, and still falls back at runtime if a saved value is
unavailable — so a stale saved mode is safe. Availability comes from
`InputModeManager.available_modes()` via `SettingsScreen._apply_mode_availability`.

**Focus-grab subscribers.** The shared `ModalScreen` base subscribes every modal to
`input_mode_changed`. While a modal is visible, a live switch **to gamepad** grabs a
sensible default focus (`_focus_default()` — overridable; the base picks the first
focusable control, `SettingsScreen` picks Back, `UnitDetailsScreen` seeds its
`SelectionCursor`). A switch **to touch** drops the stale focus highlight
(`_release_stale_focus()`). A switch to `mouse_keyboard` is deliberately left alone —
that mode lumps mouse and keyboard together, and keyboard nav still wants the
highlight. Hidden modals ignore the switch.

Visible engine-focus modals also contain focus: if focus navigation escapes to a
background control while the modal is open, the modal reclaims focus. This is backed
by a MainMenu-hosted New Game regression test so the live parent scene, not only the
isolated modal scene, is covered.

#### Hidden / not yet implemented

- **Touch Controls** (`touch_controls`, default `dedicated`) — fixed vocabulary:
  `dedicated`, `virtual_gamepad` (enforced by DOC-011 `check_docs.py`). Until
  the dedicated touch layer ships, the resolver can still fall back to the virtual
  gamepad presentation while preserving the authored preference.
- **Combat Animations** (`combat_animations`) — a `SettingsManager` field with an
  `OptCombatAnim` control that is **hidden**: no combat-animation system consumes the
  setting yet (MVP combat is instant). It will be shown when that system lands.
- **Permadeath** and **Leveling Method** are *not* on the Settings screen — they are
  per-save rules chosen on the **New Game** screen and stored on
  `GameState.campaign_rules`.

---

### Promotion / Reclass Modal

**Scene:** `PromotionScreen.tscn` (the reclass picker mirrors this layout)
**Trigger:** auto-promotion at the class cap, or using a promotion seal (the
modal/interrupt timing is owned by GDD_02 → Promotion — Trigger Timing)

A full-rect `Dimmer` + a centered `PanelContainer` listing one button per
`promotes_to` target. Each button shows the class name, a per-stat
`old +Δ -> new / cap` preview line, and the class's learned skills.

The panel is **centered via anchors with symmetric grow**, and the option
buttons **autowrap** their long stat-preview line within a capped panel width.
This is deliberate: the per-stat preview is wide, so a left-pinned fixed-offset
panel (the pre-fix layout) ran off the right edge of the screen at the play
resolution. Symmetric grow guarantees that even if content does expand, it stays
centered rather than spilling past one edge.

The reclass picker (`ReclassScreen.tscn`, Second Seal) uses the **same centered
panel**; it additionally wraps its longer option list in a `ScrollContainer`
(reclass can offer many targets, where promotion offers ≤3). That scroll container
**scrolls vertically only** (`horizontal_scroll_mode` disabled), which width-caps
each option button to the panel so its buttons **autowrap** their long
`old +Δ -> new / cap` line the same way the promotion buttons do — without a
horizontal scrollbar (playtest v0.1.5.0 #8.6). Both modals were left-pinned
originally; the reclass panel was re-centered alongside the promotion fix (code
review 2026-06-14 #1) for resolution-robustness.

---

### Game Over Screen

**Trigger:** `EventBus.map_defeat` and the following `EventBus.map_resolved`

**Layout (full-screen dark overlay):**
```
[dark overlay fades in over 1 second]

               DEFEAT

   [ Retry Map ]
   [ Reload Most Recent Save ]
   [ Load Another Save... ]
   [ Rewind (N) ]
   [ Main Menu ]
```

- "Retry Map" reloads the current map from scratch
  (player unit stats and inventory are preserved from map start — not mid-map).
  With a campaign active it also **drops the unapplied result**, so replaying a
  won map cannot advance the campaign twice.
- Unit data is **never deleted** (permadeath only sets `is_incapacitated`)
- The current screen also renders ranked standings when `map_resolved` supplies them
- "Reload Most Recent Save" uses the same Continue target/discriminator as Main
  Menu. "Load Another Save" embeds the existing `LoadGameScreen` slot picker;
  both route mid-map documents through suspend restore and between-map documents
  through campaign restore/launch, consuming a slot only after successful route.
- "Rewind" is enabled only while a prior activation and charge remain. It opens
  the same coordinate-labelled selector and stages the chosen deterministic
  active-map rewind as Map Menu before reloading GameMap.
- "Main Menu" resets map-scoped state and returns to `Boot.tscn`.

---

### Map Results Screen

Status: **Implemented 2026-07-15** (`CST-7`)
Last verified: 2026-07-15

`MapResultsScreen.tscn` is the victory-only surface. It presents ranked standings,
reward/casualty/progression summaries, campaign save status, and Continue. It waits
until the level-up/promotion queue drains, including the synchronous promotion
cascade after `level_up_finished`, before appearing.

The screen displays the exact committed `Gold earned` and resulting `Total gold`
receipt. It acquires the shared owner-counted gameplay-modal lock before visibility,
and its backdrop stops pointer input. `GameOverScreen` uses the same lock for defeat.
Map Menu refreshes a read-only `Total gold` row whenever it opens.

For a terminal node Continue reads "Finish Campaign". A node with one successor
continues without an extra prompt. A node with multiple authored successors shows
their destination labels in authored order and disables Continue until the player
chooses one. `CampaignManager` validates that the choice is a real outgoing edge;
an unresolved branch cannot prepare, commit, autosave, or move campaign position.
After selection, the successor binding and carried roster are validated before the
win commits. The commit advances the pointer and writes the battle-end autosave,
then routes to prep. `StandingsFormatter` is shared with `GameOverScreen` so the
rankings renderer remains reusable by future PvP/scenario results.
If a result is nonterminal but exposes no valid successor, the action disables as
"Campaign Data Error"; it cannot be mistaken for campaign completion.

---
