---
Role: dated
---

# Code Review (Pillar 1 — Code) — 2026-06-14b

> **Pillar:** 1 of 5 (Code — GDScript logic, architecture, perf, security)
> **Procedure:** `AGENT/Review Procedures/01_Code_Pillar.md`
> **Snapshot:** branch `awakening-compatability-refactor`, commit `e924bb4`
> **Working tree:** clean except 3 untracked sidecars (`scripts/resources/CampaignRules.gd.uid`,
> `scripts/tests/test_unit_inventory_refs.gd.uid`, `"AGENT/Docs/950MERC Promotion.png.import"`) — [CROSS] Pillar 3.
> **Baseline (assumed green, not re-run):** `check_docs.py` = PASS; `run_tests.sh` = PASS; `pytest` = not installed.
> **Delta baseline:** `AGENT/Code Reviews/code_review_2026-06-14.md`.
> **Scope:** non-test `scripts/**.gd` (ai, autoloads, core, items, resources, shared, skills, units, ui, tools).
> **Constraint:** document-only — no code/doc/data edits made.

## Pillar score: 9 / 10

## 1. Executive summary

The GDScript source is in excellent shape. Across ~13,000 lines in 59 in-scope files I
found **no Critical and no High-severity correctness bugs**. The codebase shows
consistent discipline that is rare at this stage: every cross-autoload reference uses the
documented `get_node_or_null` + `.call()/.get()` idiom (no headless footguns), every
property setter uses a backing variable (no setter recursion), all `@export` Node refs to
later-declared siblings are re-resolved in `_ready()` (`MapCursor._resolve_menu_refs`),
typed arrays are built as typed locals, and combat math reads stats exclusively through
`get_effective_stat` so modifiers propagate uniformly. `DataManager` performs thorough
boot-time validation of every content cross-reference, and most fix sites cite the
review/issue id that drove them.

The remaining findings are all **Low / Medium** maintainability and hardening items — a
hardcoded scene path inside an autoload, two cosmetic preview-placement items deferred from
the previous review, a benign nested linear scan during danger-zone painting, and a couple
of style nits. The one item I would not let drift is the `PairUpRegistry` reach into a
literal `/root/GameMap/TurnManager` path (Medium): an autoload coupling to a concrete scene
node that silently no-ops if the tree is reorganized.

Determinism note: the four raw `randi() % 100` call sites are **not** flagged as findings —
each is tagged `# rng-allow: pre-M9a (RNG-1)` and the RNG design doc
(`AGENT/Docs/rng_determinism_design_2026-06-11.md`) explicitly records `RngService` as
**Target design** not yet implemented. They are an acknowledged, gated pre-milestone state,
not undocumented raw RNG. (See Architectural observations for the watch item.)

## 2. Issues found

### [Medium] `PairUpRegistry` reaches into a hardcoded scene-node path (`/root/GameMap/TurnManager`)
- **File & Line:** `scripts/autoloads/PairUpRegistry.gd:163`
  (`var turn := get_node_or_null("/root/GameMap/TurnManager")` in
  `_apply_support_turn_state_after_lead_death`).
- **Problem:** An autoload (global, scene-independent) couples to a concrete node at a
  literal scene path. Every other autoload→system handoff in this codebase goes through an
  autoload path (`/root/...`) or an EventBus signal. If the GameMap scene tree is renamed or
  restructured (e.g. the TurnManager is nested, or the root scene is renamed), this lookup
  returns null and the function silently no-ops — a paired lead dies, the support is dropped
  onto the tile, but it is **not** marked DONE during the player phase, so it could act again
  the same turn. The failure is silent (the `if ... turn == null: return` guard hides it).
- **Root cause:** TurnManager is not an autoload and the registry has no injected reference to
  it, so the only way to reach it from a global is a literal path.
- **Recommended fix:** Prefer an EventBus signal (`support_released(support, drop_tile)`) that
  TurnManager already-connected listens for, mirroring how `unit_died` drives
  `_on_unit_died`. Alternatively inject the TurnManager into the registry at map start. Keep
  the null-guard, but make the contract explicit rather than path-coincidental.
- **Tradeoffs:** Adds one signal/wire; removes a brittle literal path. Low effort.

### [Low] `AttackPreview` couples to the HUD via a hardcoded cross-CanvasLayer path *(carried over — still open)*
- **File & Line:** `scripts/ui/AttackPreview.gd:440` (`get_node_or_null("../../HUDMainLayer/HUD")`
  in `_hud_avoid_rects`).
- **Problem:** Same class of issue as the previous review's Low #3 — the preview reaches two
  CanvasLayers up by literal path; a scene reorg silently disables HUD-rect avoidance
  (returns `[]`). Failure mode is graceful (plain viewport clamp), so it is genuinely Low.
- **Root cause:** Quickest way to read the HUD rects without changing `setup()`'s signature.
- **Recommended fix:** Inject the HUD (or an avoid-rect provider) through `AttackPreview.setup()`
  from the GameMap wiring, the same way `camera` / `camera_ctrl` are passed. Keep the null-safe
  `[]` fallback.
- **Tradeoffs:** Touches the one `setup()` call site. Deferred from the prior review's action
  plan; still acceptable to defer given the graceful degradation.

### [Low] `_place_clear_of` is single-pass over multiple avoid rects *(carried over — still open)*
- **File & Line:** `scripts/ui/AttackPreview.gd:457` (`_place_clear_of`).
- **Problem:** Nudging the panel clear of one HUD rect can re-introduce overlap with a rect
  processed earlier in the loop. With the three HUD corners this is unlikely but not
  guaranteed. Identical to the prior review's Low #4.
- **Root cause:** Deliberately simple, best-effort placement for a cosmetic concern.
- **Recommended fix:** If it ever matters, iterate to a fixpoint or pick the largest gap.
  Documented as best-effort; fine to leave.
- **Tradeoffs:** Added complexity for a cosmetic gain. Not worth it yet.

### [Low] `get_unit_at` linear scan runs inside the Dijkstra inner loop
- **File & Line:** `scripts/core/GridManager.gd:216` (`get_unit_at`) called from
  `dijkstra_costs` at `:258`, which is in turn called per-enemy inside
  `get_enemy_danger_tiles` (`:511`).
- **Problem:** `get_unit_at` is an O(units) linear scan; calling it per expanded neighbor in a
  Dijkstra flood makes a single flood O(tiles × units). The danger-zone overlay floods the
  movement range of *every* hostile unit, so painting it is O(enemies × tiles × units). On
  the current small maps (≤ ~30×30, ≤ ~50 units) this is imperceptible, but it is the one
  algorithmic hot spot that would degrade first if map/unit counts grow.
- **Root cause:** Units are stored as a flat `all_units` array with no tile→unit index.
- **Recommended fix:** When/if maps grow, maintain a `Dictionary[Vector2i, Node]` occupancy
  index updated on `register_unit`/`unregister_unit`/move, and have `get_unit_at` read it.
  Not needed at current scale — flag for the perf-watch list, do not act now.
- **Tradeoffs:** An occupancy index must be kept in sync with every position write; only worth
  it once map sizes justify it.

### [Low] `const ResourceManifest` is declared at the bottom of `GameState.gd`, after all functions
- **File & Line:** `scripts/autoloads/GameState.gd:582-583` (the `const` is the last line of the
  file, below every function).
- **Problem:** Legal in GDScript (consts are hoisted), but it breaks the file's own
  convention — every other `const`/`preload` in the project sits in the header block. A reader
  scanning the top of `GameState.gd` for its dependencies will miss it.
- **Root cause:** Likely appended when `ResourceManifest` use was added, rather than moved into
  the header.
- **Recommended fix:** Move the `const ResourceManifest := preload(...)` into the constant block
  near the top of the file.
- **Tradeoffs:** None. Pure readability.

### [Low] `damage_taken_this_map` is written and snapshotted but no gameplay path reads it
- **File & Line:** written in `scripts/core/CombatResolver.gd:777`, reset in `scripts/units/Unit.gd:345`,
  serialized in `scripts/autoloads/GameState.gd:537`; field declared `scripts/resources/UnitData.gd:86`.
- **Problem:** The field is faithfully maintained and snapshotted, but I found no consumer that
  reads it for a game effect (e.g. a Vengeance-style "+damage equal to damage taken" skill —
  `vengeance_bonus` in the combat context is set externally and is unrelated). It is forward
  plumbing for an unimplemented skill. This is consistent with the project's pattern of
  pre-wiring seams (the `M9`-stubbed skills, the Laguz fields), so it is a documentation/intent
  note rather than dead code.
- **Root cause:** Plumbing landed ahead of its consumer.
- **Recommended fix:** Add a one-line `# Consumed by <skill> in M__` comment at the field
  declaration so a future reader knows it is intentional pre-wiring, not an orphan.
- **Tradeoffs:** None.

## 3. Positive observations

1. **Headless/autoload discipline is universal.** Every singleton-to-singleton reference uses
   `get_node_or_null("/root/...")` + `.call()/.get()` and guards on `is_inside_tree()`
   (`CombatResolver._resolve_pair_partner`, `GameState.set_phase`, `Unit._bus`, the
   `PairUpRegistry` campaign gate). No identifier-level cross-autoload reference exists, so the
   documented headless `--script` footgun cannot bite.
2. **The known GDScript footguns are all handled correctly.** Setters use backing variables
   (`GameState.debug_force_levelup`, `Unit.tile_position` writing to `data.tile_position`, not
   itself); `@export` Node refs are re-resolved post-build (`MapCursor._resolve_menu_refs`); typed
   arrays are built as typed locals throughout. Nothing in the project-specific checklist (§4-C)
   is violated.
3. **Combat resolution is single-sourced and side-effect-honest.** All four strike series run
   through one guarded `_run_strike_series`, so the "either side dead?" rule cannot drift between
   them; `preview_combat` snapshots and restores the exact mutable fields any skill could touch,
   so a forecast leaves zero trace; weapon breakage is modelled in resolution so skill triggers
   only fire for attacks that actually happen.
4. **Boot-time data validation is exhaustive.** `DataManager` cross-checks class/skill/weapon/item
   refs, growth-table stat-key completeness, WEXP tracks, internal-level rules, the full map
   registry (duplicate ids/paths, grid terrain chars, tile-in-bounds, faction/turn-order
   consistency, objective-condition shape, and cross-source `unit_id` uniqueness). Bad content
   fails loud at startup via `push_error` (works in release where `assert` is stripped).
5. **The off-map-support hazard has defense in depth.** The load-bearing
   `get_living_units_of` (excludes paired supports) vs `get_all_living_units_of` (counts them)
   split is correctly applied at every call site — selection/turn-end/Tab use the former, rout
   evaluators use the latter — and `EnemyAI._living_hostiles_for_faction` adds a second,
   position-based `OFF_MAP_TILE` backstop so a future role desync can never make the AI path to
   the (-1,-1) sentinel. Each guard cites playtest v0.1.4 #4.
6. **Fix provenance is traceable.** Most non-obvious guards carry the review/issue id that drove
   them (e.g. `code review 2026-06-10 issue 2.6`, `playtest v0.1.4 #8.5`, `2.10`), which makes
   regressions easy to audit and keeps the "why" attached to the code.

## 4. Architectural observations

- **`damage_taken_this_map` and the M9 skill stubs are intentional forward seams.** `SkillHandler`
  routes ~40 unimplemented FE:A skills through `_apply_unimplemented`, which declines (returns
  `false`, burns no use) and warns once per id per session to avoid log flooding. This is a clean
  way to keep the dispatch table the single source of truth while the effects land later. Keep the
  one-line "consumed in M__" intent comments accurate as these fill in.
- **RNG centralization is the next structural step.** The four `randi()` sites
  (`CombatResolver:450,457`, `SkillHandler:189`, `Unit:1069`) are correctly tagged and
  doc-gated, but until `RngService` lands, rewind/Retry/online determinism (RNG-1…4) cannot hold.
  This is tracked design, not a code defect — listed here as the highest-leverage architectural
  follow-up, not a finding.
- **The autoload boundary is mostly clean — `PairUpRegistry` is the one leak.** Autoloads are
  otherwise self-contained and talk via EventBus or `/root` paths; the registry's literal
  `/root/GameMap/TurnManager` reach (Medium above) is the single place a global reaches into a
  concrete scene node. Closing it would make the autoload layer uniformly scene-agnostic.
- **Two near-identical class-change modals still drift independently** (Promotion / Reclass). The
  scene-side symptom (ReclassScreen centering) is now fixed (see Delta), but the underlying "shared
  chrome authored twice" remains; if a third class-change modal appears, factor the centered-panel
  base out. [CROSS] Pillar 3 owns the scene files.

## 5. Spot-check sample & method

Read in full (line-by-line): `CombatResolver.gd`, `TurnManager.gd`, `Unit.gd`, `MapCursor.gd`,
`EnemyAI.gd`, `SkillHandler.gd`, `GameState.gd`, `DataManager.gd`, `GridManager.gd`,
`PairUpRegistry.gd`, `PairUpBonusResolver.gd`, `MapCursorTargeting.gd`, `CameraController.gd`,
`ItemHandler.gd`, `InventoryEntry.gd`, `ClassData.gd`, `WeaponData.gd`, plus the relevant
sections of `AttackPreview.gd`. Targeted greps across **all** in-scope `.gd` for: raw RNG;
inline setters / setter-recursion; `@export … : Node` later-sibling refs; `_process`/
`_physics_process` per-frame work; untyped `var x =`; TODO/FIXME/HACK; stray `print`; hardcoded
node paths; `await`-then-use-node. Falsifiable claims verified by reading the code:
- Setter recursion: confirmed all setters use backing vars (`GameState:83-99`, `Unit:14-18`).
- RNG allow-tags: confirmed all four sites tagged and matched to `RNG-1` in the design doc.
- Off-map liveness split: confirmed `get_living_units_of` filters supports
  (`GameState:226-237`) and `get_all_living_units_of` does not (`:246-252`), and that
  `_eval_rout` uses the latter (`TurnManager:739,744,754`) while selection/Tab use the former.
- Swap resolve-before-flip: confirmed `MapCursor:683-688` resolves the partner before
  `swap_roles()` (prior-review #2 fix present).
- ReclassScreen centering: confirmed `scenes/ui/ReclassScreen.tscn:29-37` now uses
  `anchors_preset = 8` with symmetric offsets (prior-review #1 fix present). [CROSS] Pillar 3.

## 6. Prioritized action plan

1. **Replace `PairUpRegistry`'s `/root/GameMap/TurnManager` path with a signal or injected ref**
   (Medium; small). Removes the one silent-no-op scene coupling in the autoload layer. Best
   impact/effort.
2. **Inject the HUD into `AttackPreview` via `setup()`** to drop the hardcoded `../../HUDMainLayer/HUD`
   path (Low; small). Carried over from the prior review's deferred list.
3. **Add the occupancy-index note / `damage_taken_this_map` intent comment** (Low; trivial docs) —
   captures the two "intentional but unobvious" spots so they don't read as defects later.
4. **Move `const ResourceManifest` to the `GameState.gd` header block** (Low; trivial).
5. **`_place_clear_of` fixpoint** (Low; defer — cosmetic only).

No Critical/High items. The code is shippable as-is for v0.1.5.0; everything above is hardening,
decoupling, and readability.

## 7. Delta vs previous review (`code_review_2026-06-14.md`)

The previous review covered the v0.1.4 playtest fix diff (`3e77577..HEAD`), a narrower scope than
this full-pillar pass, so most of its findings are scene-side ([CROSS] Pillar 3) or the same UI
items re-surfaced here.

**Fixed since previous review:**
- **#1 (Medium) ReclassScreen un-centered layout** — FIXED. `scenes/ui/ReclassScreen.tscn:29-37`
  now centers via `anchors_preset = 8` + symmetric offsets. Marked `DONE 92a171b` in the prior
  doc; verified at this snapshot. [CROSS] Pillar 3 owns the scene.
- **#2 (Low) Swap leaves registry roles desynced** — FIXED. `MapCursor._commit_swap_roles`
  (`:683-688`) now resolves the partner before `swap_roles()` and bails if invalid. Verified.

**Still open (carried over, code-side, in this pillar's scope):**
- **#3 (Low) AttackPreview hardcoded HUD path** — STILL OPEN (`AttackPreview.gd:440`). Re-filed
  above as Low. Was explicitly deferred in the prior plan.
- **#4 (Low) `_place_clear_of` single-pass** — STILL OPEN (`AttackPreview.gd:457`). Re-filed above
  as Low. Deferred.
- **#5 (Low) PromotionScreen no ScrollContainer** — scene-side; [CROSS] Pillar 3 (out of this
  pillar's scope). Was deferred; not re-evaluated here.
- Prior-review action **#3 (route objective-liveness through one helper)** — NOT YET DONE. The
  `get_living_units_of` vs `get_all_living_units_of` split is still applied call-site-by-call-site
  (correctly, at every site I checked), but no single funnel helper exists, so the footgun the
  prior review flagged for future evaluators remains. Architectural watch item, not a regression.

**New this review (broader scope surfaced these):**
- **[Medium] PairUpRegistry hardcoded `/root/GameMap/TurnManager` path** — new (outside the prior
  diff scope).
- **[Low] `get_unit_at` linear scan inside Dijkstra** — new (perf watch).
- **[Low] `const ResourceManifest` placement in GameState.gd** — new (style).
- **[Low] `damage_taken_this_map` write-only** — new (intent note).

**Regressed:** none. Nothing fixed in the prior review reappeared.

## 8. Procedure friction

- **Scope boundary on `.tscn`-rooted findings is slightly awkward.** Two of the previous review's
  findings (ReclassScreen centering, PromotionScreen scroll) are scene-file issues that this
  Code pillar must *reference* to compute the delta but cannot own (Pillar 3 owns `.tscn`). The
  pillar doc handles this with the `[CROSS]` tag, which worked, but the delta section necessarily
  reports on files outside scope. Minor; the tag convention is adequate.
- **The "previous review" baseline was a narrow diff review, not a prior full Pillar-1 audit.**
  The master procedure (§3.3) says to locate "the previous audit's matching report" for deltas;
  here the most recent code review (`code_review_2026-06-14.md`) was a per-diff `/code-review`
  output, not a full pillar pass. Computing deltas against a differently-scoped predecessor means
  "new this review" partly reflects *scope difference*, not genuine new issues. I labeled these
  explicitly. A note in the pillar doc that the delta baseline may be a narrower review (and to
  distinguish "new because newly-scoped" from "newly-introduced") would help.
- **RNG check (§4-E) needed a doc cross-read to avoid a false positive.** The four `randi()` sites
  look like §4-E violations on a pure grep, but the `# rng-allow: pre-M9a (RNG-1)` tag + the RNG
  design doc's "Target design / not yet implemented" status make them correct for this snapshot.
  The pillar doc says randomness must go "through the project RNG service" — it would be worth one
  line acknowledging the documented pre-`RngService` allow-tag convention so a reviewer doesn't
  file it as a finding (or files it only as a milestone-tracking note). I treated it as the latter.
- **Everything else in the procedure applied cleanly.** The §4 A–G checklist mapped directly onto
  the code; the autoload-surface MCP (`get_autoloads`) was useful for confirming the singleton
  set; no step was inapplicable to a GDScript-only pillar.
