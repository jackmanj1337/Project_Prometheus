# Responsive UI Redesign — Design — 2026-08-06

Status: Designed (2026-08-06); size-class seam Implemented 2026-08-06, screen conversions not started. Supersedes
the 1280×720 design floor ratified by `UI-VIEWPORT-ASPECT-2026-07-31`. Tracker row:
`SMALL-SCREEN-UI-REDESIGN-2026-08-05`.
Last verified: 2026-08-06

Wireframe album (17 wireframes, 6 groups, 3 measured captures):
<https://claude.ai/code/artifact/d84bbb29-6e89-4fc7-890e-f1cc0286b9b5>

## Problem

The UI has no responsive model. Every screen is authored at roughly 1280×720 and centred in
whatever viewport it is given. That is not a portrait bug — it is wrong in every orientation,
and it has no answer at all for the two devices the project now cares about (a small Linux
handheld, and a phone cast to a large display with a Bluetooth keyboard).

Measured on 2026-08-06 against a fresh v0.7.0 web export of
`agent/from-integration/mobile-controller-web-wiring` @ `06a22b92`, driven with
Playwright/Chromium at 1179×2556 DPR 3 through `WebTestBridge`:

| Orientation | content scale | logical viewport | body type | verdict |
|---|---|---|---|---|
| Portrait | 0.5 | 2358 × 1326 | **2.7 CSS px** | unusable |
| Landscape | 1.5 | 1704 × 786 | ~8 CSS px | nothing clips, still wrong |

Portrait snaps to the 0.5 floor because 1179 backing pixels cannot show 1280 logical ones at
any factor ≥ 1. Landscape clears the floor, so nothing clips — that is the only sense in which
it works. Its menu panel occupies about a fifth of the screen and the d-pad is drawn *on top
of* it, which the owner reference rules out in its first line.

Two further measurements corrected earlier assumptions:

- **The portrait canvas band is 26% of screen height**, not the 55% `portrait_top` defines.
  `game_view_preset` defaults to `auto`, so the active controller combination's own viewport
  wins, and that combination reserves roughly three quarters of the screen for controls. The
  DS reference measures 55%, the Awakening references 54%, and the preset itself is 0.55.
- **`UnitDetailsScreen._update_responsive_layout()` already stacks its two panes below a
  hard-coded `900.0`.** An ad-hoc size class exists in the codebase today. This design
  generalises it rather than inventing something new.

## Calibration

Measured off the owner reference shots in `Incoming/reference/mobile-controller-target/` and
`Incoming/reference/portrait-3ds-awakening/` (local only, gitignored, never committed). Glyph
height is rendered text in CSS pixels on a 1179×2556 phone; row is list pitch in logical px.

| Game | System | Logical | Glyph CSS | Row |
|---|---|---|---|---|
| Fire Emblem 7 | GBA | 240 × 160 | 15.7 | 16 |
| Shadow Dragon | DS | 256 × 384 | 11.2 | 16 |
| Awakening — top screen | 3DS | 400 × 240 | 12.0 | 32 |
| Awakening — bottom screen | 3DS | 320 × 240 | 12.0 | 17.6 |
| Prometheus, portrait, today | web | 2358 × 1326 | **2.7** | — |

Fire Emblem sits between 11 and 16 CSS px across three generations. Both 3DS surfaces render
at close to **1 logical px = 1 CSS px** (top 0.94, bottom 0.97), which independently confirms
the scale model below: set `content_scale_factor` to the *measured* backing-per-CSS ratio —
which the shell already computes from the canvas rect rather than trusting `devicePixelRatio`
— and the existing 16px body font lands at 16 CSS px.

**The finding that shapes the whole design:** Awakening's bottom sheet carries 7 stats, 4
combat stats, a portrait, a name block and 5 inventory rows in 320×240 at a **17.6px row
pitch** — a third of any touch minimum. It gets away with it because *nothing on that surface
is ever tapped*. Display density and touch density are different problems. Density is a
function of the input device, not a preference about how things look.

## The model

Two inputs, one derived class. No device database.

    logical viewport = backing size ÷ content_scale_factor      (player owns the factor)
    size class       = f(logical viewport width)

| Class | Logical width | Example | Touch rows | Controller rows | Layout |
|---|---|---|---|---|---|
| Compact | < 600 | 360 × 640 | 9 | 18 | one pane; a list replaces a list |
| Medium | 600–1023 | 800 × 480 | 6 | 13 | two panes: list + detail |
| Expanded | ≥ 1024 | 1280 × 720 | 10 | 21 | three panes, detail persists |

Today's 1280×720 layouts survive as the **largest** class rather than the only one.

| Scenario | Backing | Scale | Logical | Class |
|---|---|---|---|---|
| Phone, portrait | 1179 × 2556 | 3.0 | 393 × 852 | Compact |
| Phone, landscape | 2556 × 1179 | 3.0 | 852 × 393 | Medium |
| Small Linux handheld | 1280 × 720 | 2.0 | 640 × 360 | Medium |
| Phone cast to a TV + BT keyboard | 1920 × 1080 | 1.5 | 1280 × 720 | Expanded |
| Desktop | 2560 × 1440 | 2.0 | 1280 × 720 | Expanded |
| Desktop, wants more on screen | 2560 × 1440 | 1.25 | 2048 × 1152 | Expanded |

### The size class is live, not a startup decision

**The player can resize the window manually**, and `UI-VIEWPORT-ASPECT-2026-07-31` decision 2
already committed to arbitrary sizes alongside the five 16:9 presets —
`windowed_size_status()` models preset-versus-custom today. A player can also change
`content_scale_factor` from the Settings screen while looking at it. Both mean the same thing:

**a screen can change size class while it is open, and must survive it.**

That is a hard constraint on the seam, not a nicety:

- The size class is recomputed on every viewport resize *and* on every content-scale change,
  and republished through `size_class_changed`. It is never read once at `_ready()`.
- Recompute must be debounced. A window drag emits a resize per frame, and the Compact →
  Medium boundary re-parents panes; rebuilding on every frame of a drag is the same class of
  defect as the controller's republish-during-gesture bug — a live gesture and a rebuild that
  fights it.
- **Class changes preserve state**: the selected entry, the scroll position, and any open More
  Info target survive the transition. Dragging a window wider must not lose the player's place
  or their selection.
- Boundaries need hysteresis. A window parked at exactly 600 logical px must not oscillate
  between classes; the class only changes once the width clears the boundary by a margin.
- The Settings screen is the worst case and the best test: changing Viewport Scale there
  re-classes the very screen displaying the control. The row the player is touching has to
  stay under their finger.

### Density tokens

Menu Mode selects a column; size class selects a layout. Nothing in a scene carries a
hard-coded pixel value.

| Token | Touch | Controller | Source |
|---|---|---|---|
| Row height | 48 | 28 | Material 48dp / Awakening 32px menu pitch |
| Row gap | 8 | 2 | |
| Body font | 16 | 14 | `manasoul_ui.tres` `default_font_size = 16` |
| Detail row | 44 | 18 | Awakening bottom sheet measures 17.6 |
| Minimum target | 44 | — | Apple HIG 44pt; controller uses a focus ring |
| Gutter | 16 | 8 | |
| Header / footer | 72 / 64 | 40 / 26 | controller mode gains a help strip |

## Owner decisions (2026-08-06)

| Question | Decision | Consequence |
|---|---|---|
| Design floor | **360 × 640** | The lower option. Compact is designed to it; everything larger is upside. |
| Scope | **Full redesign** | Not a portrait patch. One system across phone, handheld, desktop, cast display. |
| Scene strategy | **Responsive, not duplicated** | One scene per screen with a size-class-aware root. Duplicating eleven screens per shape does not survive a third shape. |
| Menu hosting | **Both, by mode** | Touch mode and controller mode are different densities, not a preference. |
| Images | **Always present, never informative** | The campaign editor auto-inserts a plain colour rectangle (author RGB + alpha) and a pack can be rejected for lacking one. No empty-state branches — but no icon-only controls and no portrait-only rows either. |
| Controller occlusion | **Player choice, default never** | Nothing covers the controls unless the player opts in. Fullscreen touch menus and the second-surface info panel both become opt-in. |
| Defaults | **Large buttons, controller on screen** | Touch density and a visible control band out of the box. Distributors explain the available settings; there is no in-app onboarding prompt. |
| Window resizing | **Player-resizable, arbitrary sizes** | Confirms `UI-VIEWPORT-ASPECT` decision 2. The size class is therefore live: a screen can change class while open and must preserve selection and scroll across it. |
| Compact row budget | **~4 rows, accepted** | See below. |
| More Info | **Small popup, but reachable** | Awakening's anchored tooltip in Compact, side pane at Medium and up. |
| Information density | **Ships in v1** | v1 is held for it. Full / Standard / Minimal, orthogonal to size. |
| `IMPL-VIEWPORT-ANCHORING` | **Folded in** | Closed as superseded 2026-08-06; its remaining scene work happens once, during each screen's conversion. |
| Control region (added 2026-08-06) | **Derived, not authored** | The game view is placed at the size and aspect the player picks; whatever is left over *is* the control region. Separation holds both ways by construction. The `Fullscreen Overlay` preset stays available as the player's opt-in exception, per the occlusion row above. |
| v0.7.0 | **May slip** | The bundle waits rather than shipping an unusable portrait build. |

### The Compact row budget, stated plainly

The three defaults compose to a tight result and this is accepted, not overlooked:

    360 × 640 logical, default settings
      controller band   288   (45%, never covered)
      menu region       352
        header           56
        footer           56
        content         240
      240 ÷ 56px touch row = 4.3 rows

Settings has 25+ rows, so it is roughly six screens of scrolling at the default. The occlusion
opt-in is the fix, and discovery of it rests on distributor documentation. **Every Compact
layout must therefore be genuinely good at four visible rows** — grouped headers, a filter on
the longest lists, and no screen that requires seeing two distant rows at once.

## More Info

More Info is a **mode**, not a screen, and the redesign must fit the existing model rather
than invent a parallel one.

- `UnitDetailsScreen` is a two-pane host: `Panel/HBox` = a scrolling content pane (title,
  class, stats, inventory, **skills, weapon ranks**, Pair Up, Back) beside an `InfoVBox`
  (`InfoTitle`, `InfoHint`, `InfoModifiers`, `InfoDescription`, `ScrollHint`).
- Every visible entry is a BBCode `[url]` link. Selecting one fills the info pane from
  `MoreInfoContent`, and for stats a `StatBreakdown` showing where the number came from, with
  green and red flags for stats an active buff or debuff is currently moving.
- There is a **priority cycle** across three hosts: combat forecast → character sheet →
  terrain HUD. Terrain already implements **paging** (Hidden → Description → Movement →
  Hidden), shipped in v0.2.2 — see `terrain_more_info_paging_design_2026-06-19.md`.
- Both panes carry `custom_minimum_size` 240 with 20 separation, so side-by-side needs ≥ 500
  logical px and cannot fit Compact.

**Compact presentation: a small popup anchored to the selected entry**, matching Awakening's
inline help tooltip (`Incoming/reference/portrait-3ds-awakening/inline-help-tooltip.png`).
Medium and Expanded keep the side pane, which is strictly better where it fits — no occlusion,
no dismissal, both halves readable at once.

**The accessibility contract.** All four properties exist today; the risk is losing them while
changing presentation.

1. Every entry stays selectable — stats, items, skills and ranks are all `[url]` links.
2. Reachable without a pointer — the `more_info` action cycles entries in declaration order.
3. Never behind a hidden page. Terrain hides a page to free map area; a hidden *page* is fine,
   a hidden *panel* with no way back is not.
4. The row marker (`▸`) is the focus ring. Controller mode has no hover, so the marker is the
   only signal of what the popup is about and must persist.

## Registry constraints

These come from the codebase, not from taste. Each rules out a layout that would otherwise be
the obvious choice.

- **Stats are a vocabulary.** `StatRegistry.display_stat_ids()` returns 11 ids today. Sheets
  flow that list into whatever column count the class allows. A hand-placed grid silently
  drops stat 12.
- **Images are present but not informative.** See the decision table. Rely on the box; never
  rely on the picture.
- **Fonts are pack-swappable.** The `raw_font` handler lets an author replace the face. Every
  layout survives **1.4× text extent**, proven against a generated pseudolocale at every
  durable viewport, and truncation eats the value before the label. *Raised from ~1.3× by
  `[L10N-7]` (2026-08-13): 1.3× is a real-world average, and short labels — the ones with no
  slack — routinely exceed it.*
- **Direction is metadata, not an assumption.** Every component declares its direction;
  reading and navigation structure mirror under RTL, while semantic spatial content — the
  tactical map, directional icons, numeric conventions — does not. A component that declares
  nothing defaults to non-mirroring (`[L10N-11]`/`[L10N-12]`, 2026-08-13).
- **Menu length is data.** Prep activities, difficulty tiers and map actions are open
  registries. Every one is a scrolling column — no fixed grids, no radial menus.
- **One pack is active at a time.** No screen ever shows two packs side by side.
- **Nothing covers the controls**, and controls never cover the canvas. Strict separation in
  both directions by default.

## Sequencing

> **Ordering now lives in
> [`../plans/responsive_ui_programme_2026-08-06.md`](../plans/responsive_ui_programme_2026-08-06.md).**
> That plan spans this design, mobile text entry, the control band and the v0.7.0 bundle, and
> is the one place the order is maintained. What follows is kept for the *reasons* behind each
> step, which are design decisions and belong here. Where the two ever disagree, the plan is
> right about order and this doc is right about why.

1. ~~**Close `IMPL-VIEWPORT-ANCHORING-2026-07-31` as superseded.**~~ **Done 2026-08-06.** Its
   1280×720 floor is retired and it claimed `scenes/ui/` — every screen — so it could not run
   concurrently with this. Its `content_scale_factor`-as-a-persisted-setting work is the
   foundation this design rests on and is kept.
   **Correction to the original wording:** that branch was described as unmerged and needing
   to be "picked over". It is not — `agent/from-integration/viewport-anchoring` @ `f4a7f8f6`
   is an **ancestor of `agent/integration`** (it landed via merge `eb5dac14`), so the
   `MenuScale` reconciliation and the div-by-zero / corrupt-cfg guards were already shipped.
   There was nothing to salvage. Its Windows visual pass was cancelled, not deferred.
2. ~~**Land the size-class seam.**~~ **Done 2026-08-06** — `ResponsiveLayout`, three classes,
   `size_class_changed`, both density token sets and the information-density token; debounced
   recompute on viewport resize and content-scale change, with boundary hysteresis; no screen
   changes beyond replacing the hard-coded `900.0` in `UnitDetailsScreen`. The live-resize
   behaviour was the part most likely to be got wrong quietly, so it carries headless tests
   for the boundary, the hysteresis and state preservation across a class change.
3. **Convert screens, cheapest first, one per branch.** Main Menu → Campaign Library → New
   Game (no combat coupling), then Roster → Unit sheet + More Info → Prep hub, then
   **Settings**, then the map HUD and its menus last because they interact with the control
   region.
   **Settings moved from second to late**: `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`
   claims `SettingsScreen.gd/.tscn` and `SettingsManager.gd` and is display-gated on the
   Windows return, so it will not clear before then. The same claim is why Menu Mode and
   information density are held in memory on `ResponsiveLayout` rather than persisted.
4. **The control region belongs to `MOBILE-WEB-CONTROLLER-2026-08-04`**, and two things there
   gate this work. The **landscape game-view rectangle** — under the dead-space rule the
   control region is whatever the game view leaves over, and the landscape default is full
   bleed, so it reserves nothing. And the **26% portrait band**, which must land before step 3
   reaches the map HUD: a 26% band cannot show the 12×14 tiles the map layouts are drawn
   against. Both are controller-layout data; a redesign row editing them is exactly the claim
   overlap that produced the original seven-row collision.

Text entry is the one surface this design does not cover; it is specified in
[`text_entry_mobile_compact_2026-08-06.md`](text_entry_mobile_compact_2026-08-06.md), which
inherits the size classes and density tokens defined here.

One screen per branch is what keeps this merge-able. The original seven-row path collision has
not gone away and a redesign touching every screen makes it worse.

## Verification burden

Information density shipping in v1 puts each screen at **3 size classes × 2 menu modes ×
3 densities = 18 states**. Eleven screens is 198 visual states. The Windows visual pass — one
session with a machine, a phone and a pad — is the scarce resource, so per-screen conversion
branches must carry their own headless coverage and a Playwright capture at Compact before
they queue for a visual pass.

The Playwright recipe that produced this document's measurements:

    bash scripts/export-web.sh --repo Project_Prometheus --force
    python3 -m http.server 8071 --directory builds/web/Project_Prometheus
    NODE_PATH=/opt/prometheus-web-harness/node_modules node <script>

`boot()` from `tools/playwright/lib/harness.mjs`; the bridge needs `?test_bridge=1`, and
`?content_scale=N` forces the factor, which is the fastest way to photograph a scale failure.
**Without `--force` the exporter prints "output already exists; refusing overwrite" and still
exits 0.**
