---
Type: design
Status: Decided 2026-07-31 — owner answered §G; see §0. Sections B/C/D corrected against measurement.
Last verified: 2026-07-31
---

# Viewport Expand — "Bigger Display Shows More Tiles" — Scoping

**Started:** 2026-07-11. Scoping analysis for the `UI-VIEWPORT-ASPECT` control-plane row.
It originally decided nothing — it scoped what moving from the current letterbox model to
an *expand* model would cost. **The owner answered all four §G questions on 2026-07-31**;
those answers are §0 and the row is no longer an open decision. Pairs with
[`display_scaling_resolution_design_2026-06-20.md`](display_scaling_resolution_design_2026-06-20.md)
(the V021-18/19 display design) and the `VAL-V023-DISPLAY` validation gate.

---

## 0. Decisions (owner, 2026-07-31)

Tracker row: `UI-VIEWPORT-ASPECT-2026-07-31` in `coordination/tasks.json`.

| # | §G question | Decision |
|---|---|---|
| 1 | Letterbox or expand? | **Expand + explicit UI scale.** Drop the fixed base (`content_scale_size = (0,0)`), set `content_scale_aspect = EXPAND`, and drive scale from a user `content_scale_factor` setting instead of the window/base ratio. |
| 2 | Resolution list | **Presets + free resize.** Keep the five 16:9 stops as convenience presets; allow arbitrary window sizes. |
| 3 | Mobile default zoom | **Deferred.** Mobile is not a live platform (`get_safe_area_insets()` is hardcoded zero); revisit when a real safe-area feed exists. |
| 4 | Timing | **Opens the UI/UX pass.** The anchoring refactor (task 2) lands as the first slice, before the prep hub, shop, forge, campaign editor, and compendium screens are authored. |

**Why decision 1 is not the doc's original task 1.** The measurement in §C.1 showed that
flipping `aspect` to `expand` on its own does *not* deliver §A's intent. It was corrected
before the decision was taken, not after.

**Falls out of decision 1, not yet designed:**

1. **Default-factor derivation.** "Existing players see no change" requires the shipped
   default to land on the identity diagonal (≈ `screen_height / 720`, snapped: 1.5× at
   1080p, 2.0× at 1440p). No such first-launch policy exists today.
2. **`MenuScale` reconciliation.** `MenuScale.gd:12` documents that `content_scale_factor`
   stays global 1 *deliberately*, so HUD readouts stay under the HUD Layout editor rather
   than a global window scale. Decision 1 removes that premise. `MENU_SCALE_LEVELS`
   (0.5–2.0) now sits on top of a factor that also scales — the two must be reconciled,
   not stacked, or they multiply to 4× at the extremes.
3. **Resize write-back rework.** Decision 2 means `applied_windowed_size()`'s 16:9 request
   clamp and the `_requested_window_size` / `_last_window_mode` maximize-vs-edge-drag
   detection both need revisiting; they lean on the `keep` contract by construction.

---

## A. The design intent (owner, 2026-07-11)

A **bigger display should reveal more of the map** (fewer tiles hidden → less scrolling),
**not** just scale the same view up. That is a pure comfort bonus, not a competitive lever.
Correspondingly, **campaign authors should advise players of the campaign's average map
size** so a player can judge how much of a map their display will show at the default zoom.

## B. Two orthogonal knobs (why "expand" and "pixel-perfect" don't conflict)

1. **Zoom = pixels-per-tile (chunkiness).** Discrete (2×, 3×…).
2. **Viewport extent = how many tiles fit.** Floats continuously with window size at a *fixed*
   zoom; has **no** effect on pixel-perfectness.

"Bigger display → more tiles" = hold knob 1 fixed, let knob 2 grow. The classic
impossible-triangle (integer zoom · exact screen fill · fixed tile count — pick two) is
resolved by dropping *fixed tile count*, which is the right one to drop for a tactics game.

> **CORRECTED 2026-07-31.** This section originally claimed camera zoom is "the *only* thing
> that governs pixel-perfectness". That is false under the decided model. There is a **third**
> scaler — `content_scale_factor` — and the effective source-texel→screen-pixel ratio is
> `content_scale_factor × camera zoom`. Crispness therefore depends on the *product* of two
> knobs, not on zoom alone.
>
> This is not a regression: `keep` already applies a global scale of 1.5 at 1080p (measured,
> §C.1), so today's 1080p players are running a non-integer ratio at the default zoom. The
> decided model makes it *visible and choosable* — a 1080p player can select factor 1.0 and
> get both an integer ratio (crisper than today) and 30×16.9 tiles. Note that `ZOOM_LEVELS`
> already carries stops that shimmer on their own (0.75/1.5/3.0, `CameraController.gd:38`);
> those interact multiplicatively with the factor and should be checked together, not
> separately.

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
**fixed base size**, not the aspect setting alone (see §C.1) and (2) UI that is
absolute-positioned / imperatively centred against the fixed 1280×720 base.

### C.1 Measured, not assumed (Godot 4.6.3, 2026-07-31)

The original §C called `stretch/aspect = "keep"` "the blocker" and §D task 1 called flipping
it to `expand` a one-line fix. **Measurement disproves that.** Headless probe, base 1280×720,
`content_scale_mode = canvas_items`, reading `root.get_visible_rect().size`; tiles at camera
zoom 1.0 with `TILE_SIZE = 64`:

| aspect | 1280×720 | 1920×1080 | 2560×1440 | 1280×800 (16:10) | 2560×1080 (21:9) | 720×1280 (portrait) |
|---|---|---|---|---|---|---|
| `keep` (today) | 20×11.2 | 20×11.2 | 20×11.2 | 20×11.2 | 20×11.2 | 20×11.2 |
| `expand` | 20×11.2 | **20×11.2** | **20×11.2** | 20×12.5 | 26.7×11.2 | 20×35.5 |
| `ignore` | 20×11.2 | 20×11.2 | 20×11.2 | 20×11.2 | 20×11.2 | 20×11.2 |

`expand` changes **nothing** on a larger same-aspect window: 1080p and 1440p both resolve to
an identical 1280×720 logical viewport, because the scale is the *smaller* of the two window/
base ratios and on a 16:9 window both ratios are equal. `expand` only adds area when the
window's aspect *differs* from the base. So the flip is a black-bar fix for Deck/ultrawide/
mobile — a real win, but **not** §A's design intent.

What does deliver §A: drop the fixed base and drive the scale from an explicit factor.
Same probe with `content_scale_size = (0,0)`, `aspect = EXPAND`:

| `content_scale_factor` | 1280×720 | 1920×1080 | 2560×1440 | 2560×1080 (21:9) |
|---|---|---|---|---|
| 1.0× | 20×11.2 | **30×16.9** | **40×22.5** | 40×16.9 |
| 1.5× | 13.3×7.5 | 20×11.2 | 26.7×15 | 26.7×11.2 |
| 2.0× | 10×5.6 | 15×8.4 | 20×11.2 | 20×8.4 |

Note the **identity diagonal**: 1.5× at 1080p and 2.0× at 1440p both reproduce exactly the
current 20×11.2 view. That is the migration's "nothing changes unless the player wants it to"
calibration point, and it is why decision 1 in §0 is safe to ship as a default.

Reproduce with a throwaway project and a `SceneTree` script that sets `content_scale_mode`,
`content_scale_aspect`, `content_scale_size`, and `content_scale_factor` on `root`, walks a
list of `root.size` values, and prints `root.get_visible_rect().size`. Headless is sufficient
— this is CPU-side viewport math, not rasterization. **Re-measure after an engine bump.**

## D. Work breakdown (what solving it takes)

| # | Task | Effort | Risk | Notes |
|---|---|---|---|---|
| 1 | ~~Flip `stretch/aspect` `keep` → `expand`~~ **SUPERSEDED 2026-07-31** — set `content_scale_size = (0,0)`, `aspect = EXPAND`, and make `content_scale_factor` a persisted user setting with a derived default on the §C.1 identity diagonal | small–med | med | The original "one line" does not deliver §A (measured, §C.1). Adds a new setting, a first-launch derivation, and the `MenuScale` reconciliation in §0 |
| 2 | Convert imperative menu centring to **anchors / `CenterContainer`** and delete `MenuScale._recenter()` | **large** | med | ~11 centred scenes (per `UI-VIEWPORT-ASPECT`); scroll panels need `custom_minimum_size`. This is the real cost and the bulk of the UI/UX-pass anchoring work anyway |
| 3 | Rework `SettingsManager` resolution handling | med | med | **DECIDED (§0.2): keep the five stops as presets AND allow arbitrary sizes.** `windowed_size_status()` already models preset-vs-custom, so the shape exists. Still to re-derive: the resize→`resolution` write-back, which leans on the `keep` contract (`applied_windowed_size()`'s 16:9 request clamp, `_requested_window_size`, maximize vs edge-drag detection) |
| 4 | Confirm/set `snap_2d_transforms_to_pixel` | trivial | low | Motion-shimmer correctness, independent of expand but surfaced here |
| 5 | **Mobile/DPI zoom defaults** | med | med | **DEFERRED (§0.3).** Mobile is not a live platform: `get_safe_area_insets()` is hardcoded zero until a mobile-web release feeds real values, and there is no device to measure DPI against. The concern stands — under expand a *small* phone shows *fewer* tiles — but the policy is guesswork until then. Revisit with the web/mobile release |
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

## G. Open questions for the owner — ALL ANSWERED 2026-07-31

Answers are in [§0](#0-decisions-owner-2026-07-31); kept here so the original framing is
readable next to what it became.

1. **Keep letterbox as an option, or expand everywhere?** (Steam Deck 16:10 / web / mobile.)
   → **Neither as posed.** Measurement (§C.1) showed the question was mis-framed: `expand`
   alone does not deliver §A. Answered as *expand + explicit UI scale*.
2. **Resolution list:** drop curation entirely, or keep 16:9 stops as *presets* alongside free resize?
   → **Presets + free resize.**
3. **Mobile default zoom policy** (fixed integer vs DPI-derived-then-snapped).
   → **Deferred** until mobile is a real platform.
4. Timing: bundle the anchoring refactor (task 2) **into** the UI/UX pass, or land it standalone first?
   → **Into the UI/UX pass, as its opening slice.**

Newly opened by those answers (see §0): the default-factor derivation, the `MenuScale`
reconciliation, and the resize write-back rework.

## H. Cross-references

- Control-plane row: `UI-VIEWPORT-ASPECT` (Open decision) in
  [`../plans/project_control_plane_2026-06-29.md`](../plans/project_control_plane_2026-06-29.md)
- [`display_scaling_resolution_design_2026-06-20.md`](display_scaling_resolution_design_2026-06-20.md)
- [`ui_ux_art_asset_research_2026-07-02.md`](ui_ux_art_asset_research_2026-07-02.md) (safe-zones, anchored HUD)
- Godot docs: [Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html) (stretch mode/aspect)
</content>
</invoke>
