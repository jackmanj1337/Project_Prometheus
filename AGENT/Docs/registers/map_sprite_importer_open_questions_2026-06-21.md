---
Type: register
Status: RESOLVED 2026-07-20
Last verified: 2026-07-20
Register: IMP-1..6
Resolved-in: 2026-07-20 — decision_record_2026-07-20_sprite_importer.md (contract decided; IMP-6 narrowed to minimal scope; implementation not started)
---

# FE Map Sprite Importer Productionization (§5) — Draft Plan + Open Questions

**Started:** 2026-06-21d
**Status:** **RESOLVED 2026-07-20** (see banner below; register retained as history).
Originally a planning draft; tooling/pipeline, 4 decisions pre-seeded.
**Source:** `planning_backlog_2026-06-20.md` §5; **roadmap `GDD_10` lines 2507–2528 already
list the 4 decisions**; session note 2026-06-21c Tier 2 #7.
**Companion:** `fe_map_sprite_importer_guide.md` (the initial-version tutorial).
**Code touch:** `scripts/units/Unit.gd` (Sprite2D→AnimatedSprite2D), a new
`addons/fe_importer/` plugin + an extracted pure logic module, `assets/`, `data/`.
**Pattern:** mirrors §1 ICD / §2 CST. The 4 roadmap decisions are pre-loaded as [IMP-1..4]
with recommendations; [IMP-5..6] are the productionization gaps beyond them.
Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

> **RESOLVED 2026-07-20.** IMP-1..6 are answered in
> `../decisions/decision_record_2026-07-20_sprite_importer.md`. **Read that first** —
> §1 is superseded on one point and [IMP-6] is narrower than this register recommends.
>
> **No importer exists.** There is no `addons/` directory and no importer script anywhere in
> the repository — only the guide describing one. This is **greenfield work, not
> productionization**; §1 reads as though the guide's version is present, and it is not.
>
> **[IMP-6] was narrowed to minimal scope** by owner direction: single sheet, configurable
> layout, validation — **no recursive scan, no filename parsing**. Slice-sketch step 3 drops
> out of the first pass.
>
> **`ClassData.sprite_id` already exists and is never read** — a dead class-keyed field that
> is exactly the shape [IMP-5] needs.
>
> The licensing gate below is **still in force**; it is not cleared by this decision. What
> changed is that legal input now exists — `Campaign_Pack_0`'s sources are verified CC0/CC-BY
> as of 2026-07-20.

---

> **⚠️ ASSET-LICENSING GATE — check FIRST, before sourcing/importing any art.** This importer
> ingests art into the project; *which* art is legally allowed is governed by the **legal register's
> art-asset licensing policy** — `legal_licensing_open_questions_2026-06-21.md` §4 ([LEG-4]). Summary
> for a **public MIT + Commons Clause** repo: **committed art must be CC0 or OGA-BY**; "no-redistribute"
> paid packs (PIPOYA / HEROES 99 / Zerie) are **build-only placeholder, never committed to source**;
> **Fire Emblem fan art / rips are dev placeholder only — never in a public source repo**; commissioned
> (owned) art is the cleanest path. The importer must never be treated as a license-laundering step —
> verify the source's license against §4's whitelist *before* import. (Also informs `SPRITE_SOURCE_SIZE`
> per §4.4: 32px first release ≈ fragmented CC0 + commission; the LPC CC0/OGA-BY subset is ~64px → the
> later 64px tier.)

## 1. State today (code-grounded)

- **The guide is a tutorial for the *initial* version**, not production. It hardcodes
  `FRAME_WIDTH/HEIGHT = 32`, a `down/left/right/up` row order, and generates a **standalone
  `_unit.tscn`** (`Node2D + AnimatedSprite2D`).
- **`GameMap._spawn_unit` cannot consume that scene.** Real units are the `Unit` scene
  (`Sprite2D`, HP bar, `UnitData`, faction tint via `apply_faction_visual`). The guide's
  output is incompatible — the roadmap flags this as decision #2.
- **`Unit` uses `Sprite2D`, not `AnimatedSprite2D`** today — so consuming generated
  `SpriteFrames` requires switching the unit's node type.
- **Folder convention mismatch:** the guide proposes `assets/raw/` + `assets/generated/`;
  the project splits source art under `assets/` and *resources* under `data/`.
- **`EditorPlugin` button isn't headless-testable** — the project's whole test culture is
  headless `--script` runs; a toolbar button can't be exercised in CI (decision #4).
- **`GameConstants.TILE_SIZE`** is the canonical tile size the frame size should tie to
  (rather than a magic `32`).

## 2. Draft plan (classic FE convention)

FE map-sprite convention: each unit has a small set of looping map animations —
**idle + walk per facing** (down/left/right/up), 32×32-ish frames on a fixed sheet. The
productionized pipeline:
- Raw sheets → an **importer that emits only the `SpriteFrames.tres`** (data), not whole
  scenes; the one `Unit` scene consumes them and stays the single unit pipeline.
- **Layout assumptions become exported plugin settings**, not `const`s, so a differently-laid
  sheet is a config change, not a code edit.
- **Pure extraction**: the sheet→`SpriteFrames` logic lives in a plain `RefCounted` module
  the `EditorPlugin` button calls AND a headless test can drive directly.
- **Validation/error handling**: missing sheets, wrong dimensions, bad frame counts fail
  loud with actionable messages (matching `DataManager`'s validator culture).

## 3. Open questions register

### [IMP-1] Frame size & row order — exported settings (roadmap decision #1)  **[RESOLVED]**
- **A — Make `frame_size` + `direction_order` exported plugin settings**, default
  `frame_size = GameConstants.TILE_SIZE`, order `down/left/right/up`. A mismatched sheet is
  a config change.
- **B — Keep them `const`** (edit code per odd sheet).
- **Rec: A** (the roadmap's own recommendation) — tie `frame_size` to `TILE_SIZE` so the
  importer and the grid never disagree; expose `direction_order` so a source sheet with a
  different row order needs no code edit.
- **Resolution:** **[RESOLVED 2026-07-20 — A]** Exported settings. Also lets the 32px→64px
  resolution-tier move (LEG §4.4) be configuration rather than a rewrite.

### [IMP-2] Output shape vs the `Unit` scene (roadmap decision #2)  **[RESOLVED]**
- **A — Importer emits the `SpriteFrames.tres` ONLY; `Unit` switches `Sprite2D` →
  `AnimatedSprite2D` to consume it.** One unit pipeline; importer produces data, not scenes.
- **B — Importer generates whole `_unit.tscn` scenes** (the guide's current behavior) — forks
  the unit pipeline, breaks faction tint/HP-bar/UnitData.
- **Rec: A** (the roadmap's recommendation) — do NOT fork the unit pipeline. The importer is
  a *data* producer; `Unit` gains an `AnimatedSprite2D` and a hook to select the right
  `SpriteFrames` by class/unit. The `apply_faction_visual` tint must be verified to still
  apply to `AnimatedSprite2D` (`modulate` works on both).
- **Resolution:** **[RESOLVED 2026-07-20 — A]** Importer emits `SpriteFrames` only; `Unit`
  switches to `AnimatedSprite2D`. This is the one non-additive part of the work: it touches
  `Unit.tscn`, the **typed** `@onready var _sprite: Sprite2D` at `Unit.gd:23`,
  `_apply_faction_visual()` and `set_done_appearance()`. `modulate` exists on both node types
  so tint should survive — **verify, do not assume**. `check_scene_integrity` makes a missed
  `$`-path fail loudly rather than silently.

### [IMP-3] Folder layout (roadmap decision #3)  **[RESOLVED]**
- **A — Raw art → `assets/`, generated `.tres` → `data/`** (match existing project split:
  source under `assets/`, resources under `data/`).
- **B — The guide's `assets/raw/` + `assets/generated/`** (breaks the project convention).
- **Rec: A** (the roadmap's recommendation) — generated `SpriteFrames` are resources, so they
  belong under `data/` next to the other `.tres`; raw PNGs stay under `assets/`. Keeps the
  one-place-for-resources convention `DataManager` relies on.
- **Resolution:** **[RESOLVED 2026-07-20 — A]** Raw art under `assets/`, generated `.tres`
  under `data/`.

### [IMP-4] Testability — pure-logic extraction (roadmap decision #4)  **[RESOLVED]**
- **A — Extract the sheet→`SpriteFrames` logic into a plain `RefCounted`** the plugin button
  calls and a headless test drives directly (the button becomes a thin wrapper).
- **B — Leave logic inside the `EditorPlugin`** (untestable in CI).
- **Rec: A** — matches the project's headless-test culture (the whole `scripts/tests/` suite).
  The pure module takes a texture + settings and returns a `SpriteFrames`; the test feeds a
  fixture sheet and asserts frame counts/regions per direction. DoD: a `test_fe_importer.gd`.
- **Resolution:** **[RESOLVED 2026-07-20 — A]** Pure `RefCounted`; the `EditorPlugin` button
  is a thin wrapper. A toolbar button cannot be exercised by the headless `--script` suite.

### [IMP-5] How a `Unit` selects its `SpriteFrames` (beyond the roadmap 4)  **[RESOLVED]**
Once import emits `<name>_frames.tres`, the runtime must map a unit/class → its frames.
- **A — By `class_id`** (`data/.../<class>_frames.tres`); all units of a class share map
  sprites. Fewest assets; FE-classic (map sprites are per-class, not per-character).
- **B — By `unit_id`** (per-character sprites). More assets, more distinct.
- **C — `class_id` default, optional `unit_id` override** field on `UnitData`.
- **Rec: A** (with C as a later override) — FE map sprites are per-class; keying on
  `class_id` minimizes assets and matches convention. Add a `sprite_frames_id` override on
  `UnitData` only when a special character needs unique map art.
- **Resolution:** **[RESOLVED 2026-07-20 — A, with C later]** Key on `class_id`; add the
  per-unit override when a named character needs unique art. Note `ClassData.sprite_id`
  already exists and is unread — the field is there, nothing consumes it yet.

### [IMP-6] Productionization scope — how far past the initial version?  **[RESOLVED]**
The guide's "Recommended Next Improvements" lists Priority 1 (filename parsing, recursive
scan, configurable layouts), Priority 2 (metadata, combat anims, mounted), Priority 3
(palette swap, editor UI).
- **A — Priority 1 only** (recursive scan + configurable layouts + validation). Enough to be
  a real tool; no combat anims (deferred — the project has no combat animation system yet).
- **B — Priority 1 + 2.**
- **Rec: A** — Priority 1 makes it production-usable for map sprites; Priority 2's combat
  animations have no consumer yet (combat is still frame-atomic/static — see the RngService
  §7 frame-atomicity note), and palette swap (P3) is polish. Scope to P1; revisit when a
  combat-animation milestone exists.
- **Resolution:** **[RESOLVED 2026-07-20 — NARROWER THAN REC A]** Owner chose **minimal**:
  single sheet, configurable layout, loud validation. **No recursive scan, no filename
  parsing.** There is no folder of sheets to walk yet, so a scanner would be designed against
  an imagined layout — and the real layout will follow whatever art `PACK0-ASSET-EXTRACTION`
  produces. Slice-sketch step 3 drops out of the first pass.

## 4. Slice sketch (provisional)
1. Extract pure `FeSpriteImporter` (`RefCounted`): texture + settings → `SpriteFrames`;
   `test_fe_importer.gd` ([IMP-4]).
2. Exported settings: `frame_size`/`direction_order`, folder consts → `data/` ([IMP-1]/[IMP-3]).
3. Recursive folder scan + filename parsing + loud validation ([IMP-6] → P1).
4. `Unit`: `Sprite2D` → `AnimatedSprite2D`; class-keyed frame selection ([IMP-2]/[IMP-5]);
   verify `apply_faction_visual` tint still applies.
5. Thin `EditorPlugin` button wrapping the pure module.

## 5. Test notes
- `test_fe_importer`: a fixture sheet yields the expected animations
  (`idle_down`…`walk_up`) with correct frame counts + regions; bad dimensions fail loud.
- `Unit`: a class with generated frames renders the right idle animation + keeps faction tint.
