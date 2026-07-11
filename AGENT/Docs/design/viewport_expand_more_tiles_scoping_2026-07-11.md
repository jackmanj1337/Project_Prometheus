---
Type: design
Status: Reference / scoping (not a spec) — input to `UI-VIEWPORT-ASPECT` (Open decision)
Last verified: 2026-07-11
---

# Viewport Expand — "Bigger Display Shows More Tiles" — Scoping

**Started:** 2026-07-11. Scoping analysis for the `UI-VIEWPORT-ASPECT` control-plane row
(Open decision). It **does not decide anything** — it scopes what moving from the current
letterbox model to an *expand* model would cost, so the owner can weigh it. Pairs with
[`display_scaling_resolution_design_2026-06-20.md`](display_scaling_resolution_design_2026-06-20.md)
(the V021-18/19 display design) and the `VAL-V023-DISPLAY` validation gate.

---

## A. The design intent (owner, 2026-07-11)

A **bigger display should reveal more of the map** (fewer tiles hidden → less scrolling),
**not** just scale the same view up. That is a pure comfort bonus, not a competitive lever.
Correspondingly, **campaign authors should advise players of the campaign's average map
size** so a player can judge how much of a map their display will show at the default zoom.

## B. Two orthogonal knobs (why "expand" and "pixel-perfect" don't conflict)

1. **Zoom = pixels-per-tile (chunkiness).** Discrete (2×, 3×…). This is the *only* thing that
   governs pixel-perfectness — an integer source-texel→screen-pixel ratio stays crisp.
2. **Viewport extent = how many tiles fit.** Floats continuously with window size at a *fixed*
   zoom; has **no** effect on pixel-perfectness.

"Bigger display → more tiles" = hold knob 1 fixed, let knob 2 grow. The classic
impossible-triangle (integer zoom · exact screen fill · fixed tile count — pick two) is
resolved by dropping *fixed tile count*, which is the right one to drop for a tactics game.

## C. Current state (verified 2026-07-11)

| Fact | Location | Bearing on expand |
|---|---|---|
| `stretch/mode = "canvas_items"` | `project.godot` | ✓ already the mode we want |
| `stretch/aspect = "keep"` | `project.godot` | ✗ **the blocker** — locks the logical viewport to the 1280×720 base and letterboxes; a bigger window shows the *same* tiles scaled up |
| Resolution list is **16:9-only** (`RESOLUTION_CHOICES`) | `SettingsManager.gd` | Curated *because* `keep` needs it; expand removes the constraint but changes resize write-back semantics |
| Camera zoom = **discrete, manual, player** setting (`ZOOM_LEVELS`), decoupled from window size; NOT fit-to-window | `CameraController.gd` | ✓ no auto-zoom that could silently go fractional |
| Camera math sizes itself from a **live** `get_visible_rect().size` each call, computes `tiles_w/h`, clamps to map bounds, centres axes smaller than the view | `CameraController.gd` (`_visible_world_size`, `keep_cursor_in_view`, `clamp_tile_to_view`, `nudge_by_tiles`, `_center_axes_smaller_than_view`) | ✓ **already expand-ready** — a larger visible rect just shows more tiles |
| Menu centring is **imperative** (`MenuScale._recenter` writes `target.size`/position) because `content_scale_factor` stays global 1 under `keep` | `MenuScale.gd` | ✗ absolute layout assumes a fixed base; must become anchor/container-based under expand |
| `default_texture_filter = 0` (Nearest); `snap_2d_vertices_to_pixel = true` | `project.godot` | ✓ Nearest correct. NOTE: `snap_2d_transforms_to_pixel` is not set — that (not vertices) is the one that stops whole-sprite motion shimmer; confirm intent. |

**Headline:** the camera is not the blocker — it already adapts. The blockers are (1) the
`keep` aspect and (2) UI that is absolute-positioned / imperatively centred against the fixed
1280×720 base.

## D. Work breakdown (what solving it takes)

| # | Task | Effort | Risk | Notes |
|---|---|---|---|---|
| 1 | Flip `stretch/aspect` `keep` → `expand` | trivial | — | One line; everything else is the fallout |
| 2 | Convert imperative menu centring to **anchors / `CenterContainer`** and delete `MenuScale._recenter()` | **large** | med | ~11 centred scenes (per `UI-VIEWPORT-ASPECT`); scroll panels need `custom_minimum_size`. This is the real cost and the bulk of the UI/UX-pass anchoring work anyway |
| 3 | Rework `SettingsManager` resolution handling | med | med | Drop the 16:9-only curation (or keep as *presets* + allow arbitrary); re-derive the resize→`resolution` write-back logic, which currently leans on the `keep` contract (`_requested_window_size`, maximize vs edge-drag detection) |
| 4 | Confirm/set `snap_2d_transforms_to_pixel` | trivial | low | Motion-shimmer correctness, independent of expand but surfaced here |
| 5 | **Mobile/DPI zoom defaults** | med | med | Under expand a *small* phone shows *fewer* tiles; default to a lower zoom on small screens (more tiles, smaller art) so thumbs still work. Integer-snap the DPI-derived zoom |
| 6 | Camera edge-remainder handling | small | low | A window rarely divides evenly by tile size → partial edge row/column; already mostly handled by the bounds clamp, tuck under HUD safe-zones |
| 7 | **Campaign `typical_map_size` advisory** (see §E) | small | low | New advisory pack metadata + a derived hint string on campaign-select |
| 8 | Test/validation matrix | med | — | 16:9 desktop, 16:10 Steam-Deck-ish, web/mobile safe-area; HUD/menu/camera screenshots; camera fixture that is larger than the biggest supported viewport (ties `VAL-FIXTURE-GAPS`) |

**Design floor that falls out:** the *minimum supported viewport* (worst case = mobile
portrait) becomes a hard constraint — every map, panel, and any fog/ambush beat must be
playable at the *fewest* tiles a supported device shows. Big-display "see more" is then a
comfort bonus that can never break a mechanic. Write this floor down before map authoring.

## E. Campaign `typical_map_size` advisory (the author-advises-players idea)

Advisory **data**, not engine logic — fits the open-registry / self-contained-pack model.
A pack declares e.g. `typical_map_size` / `max_map_size` (`Vector2i`); the engine renders a
derived hint on campaign-select, computed as visible-tiles = `viewport / (TILE_SIZE · zoom)`:

> *"Maps average 20×15 tiles. At default zoom a 1080p window shows ~20×11; 1440p shows
> ~26×15 (whole map). Below 720p you'll scroll vertically."*

No per-campaign engine code — same registry rule as everything else. Gives players a concrete
reason to pick a resolution, which is the payoff of the expand model.

## F. Fairness / fog note

More visible board at higher resolution is fine for single-player comfort, but it interacts
with **fog-of-war and scripted ambush** (`B6-FOW`): those assume a bounded viewport. Fog itself
hides regardless of viewport, so the exposure is only *off-screen scripted staging* becoming
visible on a big display. Decide per-mechanic, not globally; the design floor in §D covers the
downside case.

## G. Open questions for the owner

1. **Keep letterbox as an option, or expand everywhere?** (Steam Deck 16:10 / web / mobile.)
2. **Resolution list:** drop curation entirely, or keep 16:9 stops as *presets* alongside free resize?
3. **Mobile default zoom policy** (fixed integer vs DPI-derived-then-snapped).
4. Timing: bundle the anchoring refactor (task 2) **into** the UI/UX pass, or land it standalone first?

## H. Cross-references

- Control-plane row: `UI-VIEWPORT-ASPECT` (Open decision) in
  [`../plans/project_control_plane_2026-06-29.md`](../plans/project_control_plane_2026-06-29.md)
- [`display_scaling_resolution_design_2026-06-20.md`](display_scaling_resolution_design_2026-06-20.md)
- [`ui_ux_art_asset_research_2026-07-02.md`](ui_ux_art_asset_research_2026-07-02.md) (safe-zones, anchored HUD)
- Godot docs: [Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html) (stretch mode/aspect)
</content>
</invoke>
