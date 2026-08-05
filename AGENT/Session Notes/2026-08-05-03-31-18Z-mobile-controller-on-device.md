# Session Note - 2026-08-05-03-31-18Z - mobile controller on device

## Branch context

- Branch: `agent/from-integration/mobile-controller-web-wiring`
- Base branch: `agent/integration`
- Base SHA: `d61de61398f307b82a3c19aa9a9adcaef487b7ab`
- Coordination Work ID: `MOBILE-WEB-CONTROLLER-2026-08-04`

## What was done

Started from an owner report that the mobile controls would not appear on a real
phone against the served web build. They never could have: the controller was
fully built but never connected, and three independent defects each blocked it
alone.

1. **Nothing called `ControllerWebBridge.install()`.** The service was autoloaded
   and computed layouts correctly, but the only production reference to the
   bridge class was its own definition — `install()` was reachable solely from
   tests.
2. **`controller_shell.js` was not in the export.** It lives under `tools/`,
   which the web preset excluded wholesale, so the self-injection fallback read
   an absent file. Naming it in `include_filter` was **not** enough — measured:
   `exclude_filter` wins and the file silently stayed out of the `.pck`.
3. **`install()` could not see the shell even once injected.** It read the global
   via `window.get("PrometheusController")`, which compiles, runs, and yields
   NIL for a global that demonstrably exists. Measured in one frame:
   `window.get` → `TYPE_NIL`, `get_interface` → `TYPE_OBJECT`.

With the controller reaching a device, the owner asked for Slice 1 and in-app
viewport resizing, and supplied handheld-emulator reference shots as the target
look. Slice 1 turned out to be entirely unbuilt.

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`.

- `22cceb59` connected the service to the browser and gated installation on a
  touch web platform (`web_ios`/`web_android`), reusing the probe the input-mode
  resolver already trusts, so desktop browsers do not grow on-screen buttons.
- `8c83e8a8` built Slice 1: web export to `canvas_resize_policy=0`, the
  rotate-to-landscape gate deleted, `window.PrometheusWebLayout` added to the PWA
  shell, and a `metrics` message so Godot can resolve the layout model's
  fractional viewport against the real window.
- `c63d8afd` gave controls orientation-aware placement (`portrait_x`/
  `portrait_y`, portrait layouts modelled on the reference shots) and
  screen-proportional size with an on-screen clamp.
- `00ca02f5` added in-app Game View resizing: preset, size/offset sliders, 16:9
  lock, Reset, live preview, hidden off web; plus `GDD_07` vocabulary and
  `check_docs` guard `[44]`.

Remaining commits are claim-ledger and the GDD verification-date refresh.

## Gates

- `bash run_tests.sh` — all suites green; `test_controller_service` 60 passed, 0
  failed (was 44 at session start).
- `bash scripts/ci/check_gdscript_style.sh` — PASS, 301 files.
- `python3 AGENT/Docs/check_docs.py` — PASS, 44 checks. New guard `[44]`
  verified to FAIL when a preset value is removed, not merely to pass today.
- `node --test tools/web/controller_shell.test.mjs` — 29 passed, 0 failed. One
  pre-existing assertion updated: a non-flipping resize now correctly reports
  metrics.
- Browser evidence, ad-hoc Playwright probes against the served export (emulated
  Pixel 7): portrait 412×839 → canvas 412×461 top-anchored, 378px of dedicated
  control space, clean 3×3 control grid, no page errors; landscape 863×360
  unchanged; a pillarbox rect → centred 474×360 canvas with controls in the
  reclaimed margins. Desktop context renders no controls, confirming the gate.
  `scripts/playwright-drive.sh` could not be used — it has no mobile-emulation
  flag, so its contexts are desktop and the controller never installs.

## Next

**Slice 4, starting with layout persistence** — `ControllerService` rebuilds
`ControllerLayout.default_collection()` every launch, so nothing a player changes
survives a reload, and Slice 5's theming is meaningless until a layout can be
saved and chosen. Full remaining-slice state, the eight traps found while
building, and the ordering argument (Slice 4's editor before Slice 3's) are in
`AGENT/Docs/plans/mobile_web_controller_remaining_slices_handoff_2026-08-05.md`,
which lives on `agent/integration` (the docs line fences plan docs off feature
branches so a handoff cannot strand on an unmerged branch).

Known gap that is not a slice: the in-game UI is still authored for 1280×720
landscape, so portrait **runs** but is not **laid out** for portrait — menus
render small in a tall letterboxed viewport. That belongs with
`IMPL-VIEWPORT-ANCHORING-2026-07-31` and blocks Slice 3's "verify every major
screen at the minimum candidate viewport" acceptance step.

Branch is pushed and unmerged; no PR opened.
