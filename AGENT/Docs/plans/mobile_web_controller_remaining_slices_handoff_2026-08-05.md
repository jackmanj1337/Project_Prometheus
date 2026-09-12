---
Role: dated
Type: plan
Status: Planned - slices 1 and 2 built, 3 to 6 outstanding
Last verified: 2026-08-05
---

# Mobile-Web Controller — Remaining Slices Handoff

Companion to
[`mobile_web_viewport_and_virtual_controller_implementation_plan_2026-08-04.md`](mobile_web_viewport_and_virtual_controller_implementation_plan_2026-08-04.md),
which owns the full technical sequence and acceptance matrix. **That plan is still
correct; this document records what is actually built against it, the traps found
while building, and the next bounded action.**

Track ownership remains in the
[`Project Control Plane`](project_control_plane_2026-06-29.md). Execution state
lives in the workspace `coordination/tasks.json` row
`MOBILE-WEB-CONTROLLER-2026-08-04`; this document owns the build-state detail
behind it.

## 1. Where to stand

| | |
|---|---|
| Branch | `agent/from-integration/mobile-controller-web-wiring` |
| Tip | `121d47e6` |
| Base | `agent/integration` @ `d61de613` |
| Merged? | **No.** Pushed, unmerged, no PR. |

Seven commits; the five substantive ones are `22cceb59` (bridge wiring),
`8c83e8a8` (Slice 1 canvas rectangle), `c63d8afd` (orientation-aware control
placement), `00ca02f5` (in-app Game View resizing). The rest are claim-ledger
commits.

**Before anything else, re-export.** The checked-in tree and the served build
diverge the moment you touch `export_presets.cfg` or `tools/web/`, and both were
touched here:

```
scripts/export-web.sh --repo Project_Prometheus --force
scripts/serve-web-local.sh --repo Project_Prometheus --port 8060 --bind 0.0.0.0
```

`--bind 0.0.0.0` is required for the compose port map (`8060:8060`) to reach the
server; the script's `127.0.0.1` default is unreachable from the host.

## 2. What is built

**Slice 1 — complete.** Web export is on `html/canvas_resize_policy=0`. The
rotate-to-landscape gate is deleted. `window.PrometheusWebLayout`
(`apply`/`query`/`fill`/`current`) in `tools/web/pwa_shell.html` owns the canvas
rectangle. A `metrics` shell message reports the window; `ControllerService`
resolves the layout model's fractional viewport against it and publishes pixels
back over `canvas_rect_changed`.

**Slice 2 — complete and now actually reaching a device.** It was written but had
never rendered on a phone; three independent defects each blocked it alone. See
§4.

**Beyond the plan's Slice 1/2 scope**, because enabling portrait exposed them:

- Descriptors carry `portrait_x`/`portrait_y`; portrait placements follow the
  owner's handheld reference shots (pad shape for the virtual gamepad, 3×3 word
  grid for labelled actions).
- The shell sizes controls from the screen's short edge (11.5%, clamped 38–96px)
  and clamps them on-screen, re-applying on resize via `restyle()`.
- In-app **Game View** resizing: `[controls] game_view_preset` / `game_view_size`
  / `game_view_offset` / `game_view_aspect_locked`, with a Settings section
  (preset, two sliders, 16:9 lock, Reset), live preview, hidden off web.

## 3. What is NOT built

**Slice 3 — Game View submenu.** Partly pre-empted. Presets, sliders, aspect
lock, persistence and live preview exist; **the free drag editor, snap guides and
Undo do not.** The plan's "verify every major screen at the minimum candidate
viewport" is untouched.

**Slice 4 — Touch Controls submenu.** Nothing. No element editing, no profile
selector, no opacity/scale controls, no optional-control toggles, no theme
picker, no haptics, no auto-hide, no combination management. The six default
combinations exist in the model but there is no UI to choose or save one, and
**nothing persists a layout** — `ControllerService` rebuilds
`ControllerLayout.default_collection()` every launch.

**Slice 5 — campaign themes and assets.** Nothing. `controller_theme` is not a
registered validated vocabulary; `DEFAULT_THEME_COLORS` in `ControllerService.gd`
is a hardcoded five-colour dictionary. No Tier-2 asset resolution, no Kenney
import, no fixture packs.

**Slice 6 — album, migration, release gate.** Nothing. No visual album, no full
Playwright matrix run, no real-device acceptance.

## 4. Traps found the hard way

Each of these cost real time and none is discoverable by reading the code.

1. **`window.get("<global>")` returns NIL for a JS global that exists.** Measured
   in one frame against the live export: `window.get` gave `TYPE_NIL` while
   `JavaScriptBridge.get_interface` gave `TYPE_OBJECT` for the same property.
   This silently made `install()` fail closed on every platform. Always read a JS
   global through `get_interface`. It logs an ERROR when the global is undefined,
   so probe with `JavaScriptBridge.eval("typeof window.X !== 'undefined'")` first
   when a miss is expected.
2. **`exclude_filter` beats `include_filter` in the export preset.** Naming
   `tools/web/controller_shell.js` as an include while `tools/**` stayed excluded
   put *nothing* in the `.pck`, with no warning. The exclusion had to be narrowed
   to spare the file. Anything under `tools/` that must ship needs the same
   treatment.
3. **Under `canvas_resize_policy=0`, the canvas backing store is yours.** Godot
   stops touching it entirely. Left alone it stays at the HTML default 300×150
   and the whole game renders into a postage stamp. `PrometheusWebLayout` applies
   a full-window rect before the engine boots for exactly this reason.
4. **Report the WINDOW, never the canvas.** Godot cannot measure the window under
   policy 0 — `DisplayServer` reports the canvas, which is the thing being sized,
   so asking the engine is circular. Reporting the window is also what prevents a
   resize feedback loop, since Godot's reply cannot change `window.innerHeight`.
5. **Do not put the canvas rect on `layout_changed`.** That signal makes the
   shell rebuild every button, which drops whatever is held. A URL-bar collapse
   mid-press would then cancel the press. It has its own `canvas_rect_changed`.
6. **Do not write a settings override back into the active combination.**
   Mutating `_active.viewport` in place meant returning to preset `auto` left the
   last custom rect stranded — the original was already gone. The override is
   computed on demand.
7. **A fixed control size cannot serve both orientations.** 64px is comfortable
   on a 360-tall landscape window and unreachable on a 412-wide portrait one; at
   the 1.9× width the labelled pills need, it put controls off both edges.
8. **`--amend` invalidates its own claim.** The session-claim ledger keys on SHA,
   so amending a claimed commit un-claims it and the push loops. Add a separate
   claim commit instead.

## 5. The gap that is not a slice

**The in-game UI is still authored for 1280×720 landscape.** A portrait canvas is
~1082px of backing width, below the ratified design floor, so menus render small
and float in a tall letterboxed viewport. Portrait now *runs*; it is not *laid
out* for portrait, and no amount of canvas resizing fixes it. This belongs with
`IMPL-VIEWPORT-ANCHORING-2026-07-31`, not with any controller slice, but it is
the visible difference between the current build and the owner's reference shots
— where the emulated UI was authored for a small screen.

Decide this before Slice 3's "verify every major screen at the minimum candidate
viewport": that acceptance step cannot pass while the UI has no portrait layout.

## 6. Next bounded action

**Slice 4, starting with layout persistence.** It is the largest missing piece,
it is what makes every other control-related setting durable, and Slice 5's
theming has no meaning until a layout can be saved and chosen. Order:

1. Persist the active combination and the six-slot collection through
   `SettingsManager` (`ControllerService` currently rebuilds defaults each
   launch, so nothing a player changes survives a reload).
2. Profile selector (`off` / `virtual_gamepad` / `labeled_actions`) — the model
   and payload already support all three; only the UI is missing.
3. Element editing (drag, scale, opacity) on top of the existing `set_editing`
   seam, which already pauses gameplay and captures pointers.
4. Optional-control toggles and auto-hide.

Slice 3's drag editor should follow Slice 4's, not precede it: they are the same
interaction problem, and building the control editor first gives the viewport
editor its guides, snapping and Undo for free.

## 7. Evidence commands

```
bash run_tests.sh                                    # 60 controller assertions
bash scripts/ci/check_gdscript_style.sh
python3 AGENT/Docs/check_docs.py                     # guard [44] = Game View vocabulary
NODE_PATH=/opt/prometheus-web-harness/node_modules \
  node --test tools/web/controller_shell.test.mjs    # 29 shell assertions
```

Browser verification used ad-hoc Playwright probes against the served export
(emulated Pixel 7 portrait and landscape) rather than
`scripts/playwright-drive.sh`, which has **no mobile-emulation flag** — its
contexts are desktop, so `OS.has_feature("web_android")` is false and the
controller never installs. Slice 6's matrix work should add a `--device` option
to that harness; until then, browser evidence for anything touch-gated has to be
a hand-written probe.

The owner's target-look reference shots are **off-repo** at
`Incoming/reference/mobile-controller-target/` in the container workspace
(gitignored, host bind mount) with a README describing each. They are third-party
emulator screenshots — do not commit them.
