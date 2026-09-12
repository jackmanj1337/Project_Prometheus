---
Role: dated
Type: plan
Status: Planned - owner-authorized implementation
Last verified: 2026-08-06
---

# Mobile Web Viewport and Virtual Controller — Implementation Plan

Track ownership remains in the
[`Project Control Plane`](project_control_plane_2026-06-29.md). The workspace
`coordination/tasks.json` row is the execution-state source; this document owns
the detailed technical sequence and acceptance matrix.

> **Amended 2026-08-06 — the dead-space rule.** The owner ratified that the control region is
> **derived, not authored**: the game view is placed at the size and aspect the player picks,
> and *whatever is left over is the control region*. Strict separation then holds in both
> directions by construction rather than by rule, which changes how two things in this plan
> should be read.
>
> - **The landscape default is wrong and is now a blocker.**
>   `ControllerLayout._default_viewport()` returns `{x:0.05, y:0.03, w:0.90, h:0.55}` for
>   portrait — a chosen rectangle with real leftover — but `{x:0, y:0, w:1.0, h:1.0}` for
>   landscape. Full bleed leaves *zero* dead space, so landscape reserves nothing and the
>   controls can only be an overlay. It also leaves the landscape split keyboard
>   (`TEXT-ENTRY-ON-MOBILE-COMPACT-2026-08-06`) nowhere to go, which is what makes this
>   urgent rather than tidy. **4:3 is the widest rectangle that still fits a split keyboard**
>   (3 columns of 44px keys per side at 852×393), which argues for it as the landscape
>   default rather than a free choice.
>   Note this is not something Godot will do for us: an emulator gets its letterbox free by
>   showing a fixed-aspect device, whereas Prometheus runs `aspect=expand` and will fill the
>   screen unless a rectangle is chosen deliberately.
> - **`Fullscreen Overlay` remains valid, as the opt-in.** The occlusion decision is "player
>   choice, default never", so an overlay preset is the player's exception rather than the
>   model. The **editor's controller-collision guides stay useful for exactly that case** —
>   under the derived model a collision is impossible, so the guides only ever have work to do
>   once the player has opted into overlapping.
> - **The 26% portrait band defect** stays owned here and is unaffected by the amendment.
>
> Sequenced in
> [`responsive_ui_programme_2026-08-06.md`](responsive_ui_programme_2026-08-06.md).

Owner direction: remove the forced portrait rotation notice; let players reshape
the game viewport; provide a rebind-aware virtual gamepad and a fixed-semantics
labeled-action profile throughout the game; support movable, scalable, translucent
controls; save at least six combined viewport/control layouts; and leave controller
presentation open to zero-content campaign theming.

## 1. Outcome

The web app will expose two Settings submenus:

- **Game View** controls the game-canvas rectangle through presets and free dragging.
- **Touch Controls** selects and edits the controller profile, element positions,
  sizes, opacity, and theme.

Portrait and landscape are both playable. A saved combination owns its viewport,
control profile, theme, and element layout. The engine supplies a minimal black
default; activated campaigns may supply validated appearance overrides without
changing engine-owned action semantics.

## 2. Measured feasibility

The 2026-08-04 Playwright spike established the browser boundary against the actual
v0.6.1 web export:

- The current portrait gate is only `#rotate-notice` CSS in
  `tools/web/pwa_shell.html`; it is not an OS orientation lock.
- Export `html/canvas_resize_policy=2` forces the canvas back to the full browser
  rectangle after CSS resizing.
- With resize policy `0`, JavaScript changed the canvas backing size from 1200x700
  to 1000x600 and the Godot viewport snapshot changed to exactly 1000x600.
- A simultaneous two-touch probe sent one pointer to an HTML control and one to the
  canvas. `preventDefault`, `stopPropagation`, and pointer capture kept the control
  touch out of Godot while the canvas touch continued into the game.

Therefore the web shell owns the canvas rectangle and controller hit surfaces;
Godot owns the versioned model, validation, persistence, actions, settings, theme
selection, and campaign extension seam.

## 3. Architecture

```text
Settings + activated campaign data
              |
              v
  ControllerLayoutManager (Godot)
              |
      versioned JSON bridge
              |
              v
  PrometheusWebLayout (HTML/JS)
       |                 |
  canvas rectangle   controller DOM
                          |
                 abstract press/release
                          |
                          v
                 Godot InputMap actions
```

The shell must not interpret campaign rules, read arbitrary pack paths, or receive
script/CSS from a pack. It renders validated engine data only. Browser callbacks use
an explicit allow-list of registered action IDs; no evaluated action strings cross
the bridge.

The layout model is platform-neutral so a later native `Control` renderer can consume
the same saved combinations. The first renderer is web-only because only the browser
shell can create genuine controller space outside the game canvas.

## 4. Data model

Add a versioned `ControllerLayout` value model and a `ControllerLayoutManager`
autoload. Coordinates are normalized to the safe browser rectangle so they survive
different device sizes and pixel densities.

Each named combination contains:

```json
{
  "schema_version": 1,
  "id": "stable-user-id",
  "name": "Portrait Default",
  "orientation": "portrait",
  "viewport": {
    "x": 0.05,
    "y": 0.03,
    "width": 0.90,
    "height": 0.55,
    "aspect_locked": true
  },
  "profile": "labeled_actions",
  "theme": "prometheus:minimal_black",
  "global_opacity": 0.72,
  "elements": []
}
```

Requirements:

- Store a named array rather than six hardcoded slots; expose at least six readily
  available save positions in the UI.
- Save portrait and landscape variants independently, with an explicit `both`
  option for users who want one shared layout.
- Clamp loaded geometry to the current safe area and preserve the pre-clamp authored
  values so returning to the original orientation/device does not accumulate drift.
- Version and migrate layouts. Corrupt or unknown versions fail to the default rather
  than blanking the game viewport.
- Release all held actions before applying a different combination.

## 5. Game View submenu

Initial presets:

1. Fullscreen Overlay
2. Landscape Side Grips
3. Landscape Bottom Dock
4. Portrait Game Top / Controls Bottom
5. Portrait Centered Game
6. Compact One-Handed
7. Custom

Editing provides four edge handles, four corner handles, whole-rectangle dragging,
optional 16:9 locking, safe-area guides, controller-collision guides, Undo, Reset,
save/load/rename/delete, and a minimum-size guard. Start the minimum candidate at
640x360 logical pixels but ratify it only after the complete UI album and physical
device pass.

On Web, change the export canvas policy to `0`. `PrometheusWebLayout` sets both the
CSS rectangle and backing-buffer size (`CSS pixels * devicePixelRatio`) and publishes
the observed rectangle back to Godot. `ResizeObserver`, orientation changes, safe-area
changes, and visual-viewport changes reapply the normalized layout.

## 6. Touch Controls submenu

Options:

- Off / Virtual Gamepad / Labeled Actions
- Edit layout
- Global opacity and scale
- Per-element position, size, and opacity
- Add/remove optional controls
- Theme
- Haptic feedback
- Auto-hide delay
- Save combination / Reset

Editing pauses gameplay and captures every pointer. Normal play captures only pointers
that begin on a controller hit surface; other pointers continue to the canvas. Every
held pointer uses pointer capture. Pointer up, pointer cancel, page blur, visibility
loss, orientation change, profile change, and editor entry all release their actions.

### 6.1 Virtual Gamepad

Default elements are D-pad, A/B/X/Y, L/R, Start, and Select. Elements invoke logical
actions, while their displayed icons follow the active gamepad binding profile. If
Confirm moves from A to B, the Confirm control displays B and still invokes Confirm.
Do not attempt to synthesize a trusted browser Gamepad device.

### 6.2 Labeled Actions

Default elements include Confirm, Back, Menu, Info, More, Previous Unit, Next Unit,
Zoom In, and Zoom Out. Labels and semantics are engine-authored and do not change with
physical-device rebindings. Adding a future action is a registry entry, not a closed
enum or `match` edit.

## 7. Theme and zero-content seam

Register an open, versioned `controller_theme` document family. A theme may name:

- background media or a solid color;
- normal and pressed button media;
- D-pad and joystick media;
- font, label color, outline, and highlight color;
- default opacity;
- optional sound/haptic presentation tokens.

All media references are logical IDs resolved through the existing Tier-2
`asset_registry`. A campaign supplies appearance only: it cannot introduce actions,
JavaScript, CSS, scenes, or executable resources.

Theme precedence:

1. User-selected compatible theme
2. Active campaign preferred theme
3. `prometheus:minimal_black`

The default uses a curated subset of Pack 0's CC0 Kenney Mobile Controls assets and a
flat black background. Preserve the Kenney license metadata even though attribution is
not required.

## 8. Implementation slices

### Slice 1 — shell and model foundation

- Remove the portrait notice.
- Switch the web export to canvas policy `0`.
- Add `PrometheusWebLayout` with apply/query/orientation callbacks.
- Add the versioned pure layout model with normalization, validation, and migration.
- Add focused Godot tests and Playwright viewport/touch-routing probes.

### Slice 2 — global input and renderer

- Replace the map-local touch overlay with a persistent controller service.
- Add open action descriptors and press/release reference counting.
- Render both profiles in the shell.
- Add lifecycle cleanup and simultaneous canvas/controller touch coverage.

### Slice 3 — Game View submenu

- Implement presets, free editor, aspect lock, guides, Undo/Reset, and persistence.
- Verify every major screen at the minimum candidate viewport.

### Slice 4 — Touch Controls submenu

- Implement element editing, profile selection, opacity/scale, optional controls,
  theme selection, haptics, auto-hide, and combination management.

### Slice 5 — campaign themes and assets

- Register and validate `controller_theme`.
- Adopt Tier-2 asset resolution through a safe web-media bridge.
- Import the minimal Kenney subset.
- Add fixture packs proving valid overrides and fail-closed invalid themes.

### Slice 6 — album, migration, and release gate

- Produce a visual album for minimal black, outlined black, parchment RPG,
  stone-and-gold, translucent glass, and high-contrast accessibility candidates.
- Run the complete Playwright matrix and project suite.
- Export a PWA build and complete real-device iPhone, iPad, and Android acceptance.

## 9. Verification matrix

Godot tests cover serialization/migration, six-plus combinations, orientation
selection, normalized clamping, theme precedence, asset validation, binding-driven
icons, fixed labeled semantics, multi-pointer reference counts, and forced release.

Playwright covers portrait/landscape phones and tablets; DPR 1/2/3; every preset;
custom resizing; rotation while held; simultaneous controller/canvas touches; inside,
outside, and overlapping controls; both editors; browser blur; PWA offline reload;
and screenshot albums at the minimum viewport and 200% menu scale.

Physical-device acceptance remains mandatory for iOS PWA safe areas, browser chrome,
real three-plus-finger input, haptics, palm/edge behavior, and subjective controller
feel. Visually unverified work stays on its separate playtest branch until accepted.

## 10. Coordination and risks

- `MOBILE-WEB-UX-GAPS-2026-08-03` already owns `InputModeManager.gd` and the safe-area
  service. This feature must integrate with that work rather than editing those paths
  concurrently.
- Pack media lives under `user://`; the shell cannot address it directly. Godot must
  publish validated decoded bytes through revocable object URLs or another bounded
  byte bridge.
- A canvas resize can make existing menus technically alive but unusable. The minimum
  guard is gated by the all-screen album, not map-only evidence.
- Controller DOM is gameplay input and must remain dependency-free, CSP-compatible,
  keyboard-inert, and fully covered by stuck-input cleanup tests.
