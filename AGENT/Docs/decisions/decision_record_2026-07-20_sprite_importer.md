---
Role: topic
Type: decision-record
Status: Applied
Last verified: 2026-07-20
Decision IDs: IMP-1..6
---

# Decision Record — Map-Sprite Importer Contract (2026-07-20)

## Context

`map_sprite_importer_open_questions_2026-06-21.md` framed IMP-1..6 as
*productionization* of the importer described in
`guides/fe_map_sprite_importer_guide.md`.

## State check

**No importer exists.** There is no `addons/` directory and no importer script
anywhere in the repository — only the guide describing one. This is greenfield
work, not productionization of existing code. The register's §1 reads as though
the guide's version is present; it is a tutorial, not shipped code.

Two other facts that shaped the answers:

- **`ClassData.sprite_id` already exists** (`scripts/resources/ClassData.gd:65`,
  authored as `""` in every class `.tres`) and is **never read by any script**. A
  dead, class-keyed field — precisely the shape [IMP-5] needs.
- **The register's asset-licensing gate is now cleared.** Its banner says to check
  §4 before sourcing any art. As of 2026-07-20 `Campaign_Pack_0`'s sources are
  verified CC0/CC-BY (`Campaign_Pack_0/CREDITS.md`), so the importer has legal
  input available for the first time. The gate itself does not go away — see
  "the importer is not a laundering step" below.

## Decisions

| ID | Decision | Rationale |
|---|---|---|
| IMP-1 | **Exported settings, as recommended.** `frame_size` defaults to `GameConstants.TILE_SIZE`; `direction_order` exposed. | Ties the importer to the grid so the two cannot disagree, and an oddly laid sheet is a config change rather than a code edit. |
| IMP-2 | **Importer emits `SpriteFrames` only; `Unit` switches `Sprite2D` → `AnimatedSprite2D`.** | Keeps one unit pipeline. Generating whole scenes forks it and loses faction tint, HP bar, and `UnitData`. |
| IMP-3 | **Raw art under `assets/`, generated `.tres` under `data/`.** | Matches the existing split that `DataManager` relies on; the guide's `assets/raw` + `assets/generated` breaks it. |
| IMP-4 | **Pure `RefCounted` module; the `EditorPlugin` button is a thin wrapper.** | The whole test culture is headless `--script`. A toolbar button cannot be exercised in CI; a pure module can. |
| IMP-5 | **Key on `class_id`, with a per-unit override added later.** | Map sprites are per-class by convention, which minimises assets, and `sprite_id` already exists for it. A `UnitData` override lands only when a named character needs unique art. |
| IMP-6 | **Minimal scope — single sheet, configurable layout, no recursive scan.** *(Narrower than the register's Priority-1 recommendation.)* | Owner direction. Recursive scan and filename parsing are speculative until there is a folder of sheets to process; add them when that exists. |

## Consequences

### IMP-6 is deliberately narrower than the register recommended

The register recommended Priority 1: recursive scan, filename parsing,
configurable layouts, validation. The decision takes **only** the configurable
layout and validation, dropping the scan and filename parsing.

This is a considered narrowing, not an oversight. There is currently no folder of
sheets to walk — building a scanner first would be designing against an imagined
asset layout, and the layout is likely to be decided by whatever art is actually
sourced (`PACK0-ASSET-EXTRACTION`). Slice sketch step 3 in the register drops out
of the first pass accordingly.

### The `Unit` node-type switch is the risky part

Everything else is additive; this is not. `Sprite2D` → `AnimatedSprite2D` touches:

- `scenes/units/Unit.tscn` — the node itself
- `scripts/units/Unit.gd:23` — a **typed** `@onready var _sprite: Sprite2D`
- `_apply_faction_visual()` and `set_done_appearance()` — both drive `modulate`

`modulate` exists on both node types, so tint and done-darkening are expected to
survive; that expectation should be verified rather than assumed. The
`check_scene_integrity` pre-commit check validates `@onready` `$`-paths against
the scene, so a missed rename fails loudly rather than silently at runtime — the
risk here is visible, which is why the switch is acceptable.

### The importer is not a licence-laundering step

Worth restating because a tool that ingests art invites exactly this mistake:
running art through the importer does not change its licence. The `LEG-4`
whitelist still governs what may be committed — CC0 or CC-BY/OGA-BY only,
no-redistribute paid packs are build-only placeholder, and FE-derivative material
belongs in `Campaign_Pack_FE`, which is internal-only
(`decision_record_2026-07-20_leg_licensing_gate.md`,
`Campaign_Pack_FE/NOTICE.md`). Verify a source's licence *before* import.

### Frame size and the resolution tier

`frame_size` defaulting to `GameConstants.TILE_SIZE` interacts with the sourcing
analysis in LEG §4.4: the 32px first release draws on fragmented CC0 sets plus
commissioned art, while the broader CC0/OGA-BY pool (LPC) is ~64px and fits a
later tier. Because the setting is exported rather than `const`, moving tiers is
configuration, not a rewrite — which is a second reason to prefer [IMP-1] A.

## Follow-ups

| Task | What |
|---|---|
| `IMP-IMPORTER-CORE-2026-07-20` | Pure `RefCounted` sheet→`SpriteFrames` module with exported `frame_size`/`direction_order`, loud validation, and `test_fe_importer.gd`. Single sheet; no scan. |
| `IMP-UNIT-ANIMATED-SPRITE-2026-07-20` | `Unit`: `Sprite2D` → `AnimatedSprite2D`, class-keyed frame selection via `sprite_id`; verify faction tint and done-appearance still apply. |
| `IMP-EDITOR-PLUGIN-2026-07-20` | Thin `EditorPlugin` button wrapping the pure module. |
