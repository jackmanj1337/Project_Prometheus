---
Role: dated
Type: design
Status: Reference
Last verified: 2026-07-12
---

# Using 16-Bit-Style Pixel Art For A Demo — Research Summary

Status: **Reference** — research input for a future art-direction decision,
not itself a scheduled or ratified change.
Last verified: 2026-07-12

## What this covers

A research pass on replacing the placeholder art
(`GDD_06_Maps_Objectives.md` — "Tile Setup in Godot", Implemented (placeholder
art)) with real 16-bit-era-style pixel art for a demo (`REL-WEB-DEMO` in
`GDD_00_Overview.md`), covering: current baseline, sourcing methods and cost,
Godot pipeline constraints, a specific readability question (native low-res
art vs. manually upscaled art), and consequences worth weighing before
committing time to it. Companion to the narrower
[`tile_size_native_res_rescale_assessment_2026-07-12.md`](tile_size_native_res_rescale_assessment_2026-07-12.md),
which covers only the cost of changing `GameConstants.TILE_SIZE` itself.

## Current baseline

- Unit and terrain art is not placeholder in spirit only — it's programmatically
  generated. Git history: `Add placeholder asset generator and 13 colored
  64x64 PNGs`. `GDD_06` marks it explicitly: **Implemented (placeholder
  art)**.
- `GameConstants.TILE_SIZE = 64` (`scripts/shared/GameConstants.gd:10`) is the
  authoritative grid pixel size; `scripts/tools/generate_placeholder_assets.gd`
  generates every placeholder PNG at exactly that size.
- Real pixel art already exists in the repo for UI chrome: `Draft UI assets/`
  holds four "Tiny RPG" packs (Dragon Regalia GUI, Font Kits I-III, Dark
  Dwellers, Mana Soul GUI) by Gabriel "tiopalada" Lima, all **CC0 1.0**
  (verified by extracting each pack's `license.html`/`README.html` — no
  attribution required). These cover menus/portraits/fonts/cursors, not
  battle unit sprites or terrain tiles — that gap is what this research is
  about.
- `Unit.gd` renders units as a plain `Sprite2D` with no `SpriteFrames`/animation
  state machine — there is no idle/move/attack animation surface today, only
  a static texture.

## Sourcing methods, ranked by cost/effort

1. **CC0/permissive asset packs (itch.io)** — cheapest, fastest, and the same
   move already made for UI. Tactical-RPG-tagged packs commonly run $3-$15,
   some free. Commercial-use terms vary per creator — verify per pack, don't
   assume Tiny RPG's CC0 terms extend to a different artist's pack. Main
   difficulty: mixing packs from different artists tends to break palette/style
   coherence — the #1 way "16-bit" ends up reading as inconsistent rather than
   deliberate.
2. **Commission a single artist** — best style consistency, worst cost/time
   scaling. Rough industry anecdote: ~1hr for a still + ~30min per additional
   frame at typical pixel-artist hourly rates; a handful of classes x
   idle+attack frames adds up quickly for a demo slice.
3. **AI-assisted generation + manual cleanup** — fast/cheap up front, but
   16-bit-era art has hard constraints (palette lock, exact pixel grid,
   small-size silhouette readability) that generative tools routinely violate;
   expect a cleanup pass per sprite regardless.
4. **Draw it yourself** — free in dollars, steep skill/time cost (palette
   discipline, animation principles).

Given the project's own scope framing (`GDD_00` — *"this project is first a
learning project and portfolio display piece... commercial-release
optimization is not the primary lens"*), option 1 (CC0 packs, same pattern as
the existing UI work) is the consistent default unless art itself is a skill
being deliberately demonstrated.

## Godot pipeline constraints (grounded in this codebase)

- **Import settings**: pixel art needs Filter=Nearest, Mipmaps=Off,
  Compression=Lossless — different from Godot's linear-filter default.
- **`TileSetAtlasSource.texture_region_size` crops, it does not stretch.**
  `generate_tilesets.gd` sets both `TileSet.tile_size` and
  `texture_region_size` to `GameConstants.TILE_SIZE`. Any source PNG used as
  a terrain/overlay atlas source must already be exactly that pixel size —
  supplying a smaller native-resolution image does not get auto-scaled into
  the tile; it gets silently cropped to its top-left corner. See the
  companion `TILE_SIZE` doc for the full breakdown.
- **`Sprite2D` units are not auto-scaled either.** `Unit.gd` positions a
  unit's *anchor* from `TILE_SIZE` but never sets `Sprite2D.scale` — a unit
  texture authored at a different resolution than the tile grid will overflow
  or underflow the tile footprint, not resize to fit.
- **Net effect**: regardless of what native pixel resolution art is *drawn*
  at, every source file that ships into this pipeline today must end up
  exactly `TILE_SIZE`x`TILE_SIZE` pixels (64x64) before import — "author small,
  then upscale to 64px before dropping it into `assets/`" is the correct
  workflow under the current architecture, not "author small and let the
  engine scale it."

## Readability question: does native low-res + integer zoom look crisper than manually upscaled art?

Investigated directly because it's the natural follow-up once you know art
must land at 64px either way: is there any rendering-quality reason to author
natively at a smaller size and let Godot's camera zoom do the 4x, versus
authoring at 16px and manually upscaling to a 64px file by hand?

**Finding: no.** Godot's nearest-neighbor sampling only ever sees the final
texel grid at render time — it has no notion of "this 64px texture started
as a 16px image." A hand-upscaled 64px file and a natively-drawn 64px file
are pixel-identical inputs to the renderer. Shimmer (uneven pixel-block
widths during camera pan/zoom) is governed entirely by whether
`(texture size x zoom)` lands on a power-of-two-friendly value, not by what
resolution the art was originally drawn at. This project's own code already
documents the exact boundary:

`CameraController.gd:35-41`:
> Power-of-two-friendly common stops keep the pixel-snap
> (Rendering/2D/Snap) crisp at the usual zooms; 0.75/1.5/3 are available but
> shimmer slightly.

This matches Godot's broader, well-documented `snap_2d_transforms_to_pixel`
jitter behavior (reported even against bare 16x16 textures — see Sources).
So: changing the art's native authoring resolution, on its own, buys nothing
for crispness. The two things that actually matter are (a) sticking to
power-of-two zoom stops — already true of this project's `ZOOM_LEVELS`
default set (0.25/0.5/1/2/4) — and (b) keeping every source file at exactly
`TILE_SIZE`, per the pipeline constraint above.

## Consequences worth flagging

- **Scope creep against the roadmap**: `GDD_10_Roadmap.md` treats
  `REL-WEB-DEMO` as a release gate after campaign-loop foundations, not a
  resequencing trigger. Real art is easy to let balloon into an open-ended
  side quest that competes with that gate.
- **Genre saturation**: 16-bit SRPG pixel art is one of the most common indie
  aesthetics; per the project's own Design Pillars (`GDD_00`), the intended
  differentiator is rules-faithful, readable systems — not art fidelity.
  Worth not over-investing here relative to that.
- **License hygiene**: mixing several CC0/commercial-use packs is fine
  legally but needs a running note of what's CC0 vs. attribution-required vs.
  "game use only," the same instinct already applied to the existing `Draft
  UI assets/` packs.

## Recommendation

Source terrain/unit/cursor art from CC0 or clearly commercial-use-licensed
packs (matching the existing UI asset approach), resize everything to exactly
64x64 before import (per the pipeline constraint above — don't rely on any
auto-scaling that doesn't exist), keep `GameConstants.TILE_SIZE` at 64 (no
rendering benefit to changing it, see companion doc for the real cost if ever
attempted), and keep the effort bounded relative to `REL-WEB-DEMO`'s actual
gate criteria rather than letting art polish compete with campaign-loop work.

## Cross-references

- `AGENT/GDD/GDD_00_Overview.md` — Project Scope (`SET-011..014`),
  `REL-WEB-DEMO`, Design Pillars.
- `AGENT/GDD/GDD_06_Maps_Objectives.md` — "Tile Setup in Godot" (placeholder
  art status, `TILE_SIZE` citation).
- [`tile_size_native_res_rescale_assessment_2026-07-12.md`](tile_size_native_res_rescale_assessment_2026-07-12.md) —
  cost of changing `TILE_SIZE` itself, tracked as `B8-TILE-RESCALE`.

## Sources

- [Pixel Art Jittering - Godot Forum](https://forum.godotengine.org/t/pixel-art-jittering/75305)
- [Jitter on player sprite during movement after enabling "Snap 2D Transform to Pixel" - Issue #71074, godotengine/godot](https://github.com/godotengine/godot/issues/71074)
- [Physical movement and snap 2d transforms to pixel option causes jitters - Issue #63185, godotengine/godot](https://github.com/godotengine/godot/issues/63185)
