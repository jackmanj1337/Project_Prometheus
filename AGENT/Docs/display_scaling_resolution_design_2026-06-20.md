---
Type: design
Status: Target design
Last verified: 2026-06-23
---

# Display Scaling & Resolution — Design (V021-18 / V021-19) — 2026-06-20

Status: Target design
Last verified: 2026-06-20

Companion handoff: `AGENT/Docs/handoff_2026-06-20_v0.2.3.md`
Coupled work: `AGENT/Docs/debug_web_playtest_plan_2026-06-20.md` (+ its handoff
`AGENT/Docs/handoff_2026-06-20_web_debug.md`)

## Problem (v0.2.1 triage)

Two deferred display findings were split out of v0.2.2 into a single coupled v0.2.3 build:

- **V021-18 — crisp scaling.** Menu Scale today zooms whole panels with `Control.scale`
  (`MenuScale.apply_to()` sets `target.scale = Vector2.ONE * _fit_factor(...)`). Scaling the
  rendered raster softens text and UI at any non-1× size. We want font/metric/control sizing
  so menus and the HUD stay sharp at 0.75×–2.0×.
- **V021-19 — native resolutions.** `SettingsManager.RESOLUTION_CHOICES` stops at
  `1920x1080`. We want native `2560x1440` and `3840x2160` windowed options, plus a
  documented Steam Deck / mobile / safe-area policy.

These rework the same display surface, so they ship together rather than as separate patches.

## Why this is now web-aware

The debug Web playtest (iPhone 14 Pro, see the coupled plan) lands in the **same window**
and touches the **same renderer and scaling assumptions**. Treating the two as one display
program avoids building the crisp-scaling path twice and avoids two conflicting renderer
states. Concretely:

- **Shared renderer prerequisite.** Web export needs the **Compatibility** renderer (Web
  does not support Forward+/Mobile). The project currently sets no `rendering_method` key in
  `project.godot`, so it defaults to **Forward+**. Both workstreams need the switch to
  `gl_compatibility`, and it must happen **once**, validated against both desktop and Web,
  not flipped independently by each track.
- **Crispness matters more on the phone.** Forward+→Compatibility plus the iPhone's high-DPI
  canvas makes blurry `Control.scale` text the most visible defect on the web build. V021-18
  is the durable fix; Menu Scale + Map Zoom are the interim readability workaround the web
  checklist already leans on.
- **Safe-area plumbing is shared.** V021-19's mobile/safe-area policy is the same margin
  concept the web shell reserves with `env(safe-area-inset-bottom)`. Define one model.
- **Touch path already exists.** V021-17 `mouse_cursor = "click"` is the deliberate mobile
  input mode; the web build defaults to it. This design must not regress it when reworking
  scale.

This design does **not** absorb the web shell, export preset, or input bridge — those stay
in the web plan. It only fixes the renderer/scaling/resolution foundation they both stand on.

## Current implementation seams (verified 2026-06-20)

- `scripts/autoloads/SettingsManager.gd`
  - `RESOLUTION_CHOICES = ["1280x720", "1600x900", "1920x1080"]` (line 46).
  - `MENU_SCALE_LEVELS = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0]` (line 51).
  - `_apply_menu_scale()` resets `Window.content_scale_factor = 1.0`, then calls
    `get_tree().call_group("menu_scale_targets", "apply_menu_scale", get_menu_scale())`.
  - `_apply_display()` drives window mode + resolution via `DisplayServer`, windowed size
    kept separate from fullscreen native size; confirm-or-revert via `DisplayConfirmDialog`.
- `scripts/ui/MenuScale.gd` — `apply_to()` sets `pivot_offset` to centre and
  `target.scale = Vector2.ONE * _fit_factor(target, factor)`. `_fit_factor()` is the V021-08
  fit clamp (keeps tall menus reachable). `scaled_size()` reports `size * scale`.
- `scripts/ui/SettingsScreen.gd` — window mode + resolution are confirm-gated enum rows;
  Menu Scale is a slider over `MENU_SCALE_LEVELS`.
- `scripts/ui/HUD.gd` / `scripts/ui/HudLayoutEditor.gd` — HUD layout persists
  `{ offset, scale }` per panel and applies scale via `panel.scale`. V021-04 terrain-corner
  snap is the related cosmetic seam (bottom-right corner scales from a top-left pivot).
- `project.godot` `[rendering]` — `default_texture_filter=0` (nearest) and
  `snap_2d_vertices_to_pixel=true`; **no `renderer/rendering_method` key** (so Forward+).
- `project.godot` `[display]` — `window/stretch/mode="canvas_items"`, base viewport
  `1280x720`, `window/stretch/aspect` unset (defaults to `keep`). This stretch foundation
  already scales a 16:9 canvas crisply to any window/device — it is the same mechanism the
  web 16:9 canvas relies on. Build with it; do not replace it.
- **No UI Theme resource exists.** Screens use the engine default theme plus code-built
  styleboxes (e.g. the HUD editor). There is no central font-size source to scale today.

## Design decisions

### D1 — Renderer: switch to Compatibility globally, first

Add `renderer/rendering_method="gl_compatibility"` (and the GL ES3 mobile fallback key) to
`project.godot`. This is the shared prerequisite for both tracks and the riskiest single
change, so it lands as **its own commit ahead of the scaling rework**, with a full-suite run
and a desktop live-smoke. Rationale: the roadmap already ratified Compatibility for Web; the
game is 2D-dominant so the Forward+ feature set is not needed. Doing this first means
V021-18 crispness is tuned against the renderer the web build will actually use.

Recommendation: **accept.** Sequencing the renderer switch first de-risks both tracks.

### D2 — Crisp Menu Scale: font/metric sizing, leave `Control.scale` at 1

Replace the `Control.scale` zoom in `MenuScale.apply_to()` with crisp sizing.

Why not just `content_scale_factor`: it is the natural DPI knob and the stretch system is
already `canvas_items`, but it is **global** — it would scale the HUD and the game map too,
re-breaking the v0.2.0 Menu/HUD split. So Menu Scale stays a menu-only mechanism. (Current
code already resets `content_scale_factor` to 1.0 in `_apply_menu_scale()`; keep it global-1
and scale menus via the theme path below.)

- Introduce **one base UI Theme resource** (none exists today) and scale a menu by setting a
  scaled Theme on the menu's **root** Control, which propagates font sizes/metrics to its
  children. One scale point per menu — not per-node `theme_override` scattered across screens.
  Leave `target.scale = Vector2.ONE` for menu/modal text surfaces.
- Keep a requested-factor clamp equivalent to `_fit_factor()` so large menus (character
  sheet) still fit top/bottom at 2.0× — V021-08 must not regress.
- Preserve contextual-menu anchoring for Action/Item/Weapon menus.
- **Theme isolation:** derive a scaled Theme per factor from the base (or clone per root); do
  not mutate the shared base resource in place.

Keep the public `apply_menu_scale(factor)` / `MenuScale.apply_to()` API surface; many screens
call it directly. Change the mechanism behind it, not the call sites.

Recommendation: **accept** the base-theme/metric path; avoid `Control.scale` for text and
keep `content_scale_factor` global at 1.

### D3 — HUD layout panel scale: stage, do not block v0.2.3 on it

V021-18 names "Menu/HUD". The HUD `panel.scale` path is a larger, drag-editor-coupled change.
Decision point in this doc: migrate HUD scale to the crisp path **now** only if it can keep
the V021-04 terrain-corner snap stable; otherwise keep HUD on `panel.scale`, document the
limitation, and leave V021-04 explicitly deferred in GDD_10 + the check-back doc.

Recommendation: **stage it.** Land crisp menu/modal text first (the web-visible win), and
close V021-04 with the HUD migration only if the new path makes corner snap stable. The web
build tolerates HUD-scale softness far better than menu-text softness.

### D4 — Native resolutions + aspect policy

- Add `2560x1440` and `3840x2160` to `RESOLUTION_CHOICES`; reset stays `1280x720`; malformed
  values still parse to `Vector2i.ZERO`.
- Update `SettingsScreen` resolution enum labels; confirm-or-revert flow unchanged.
- The desktop game keeps its **16:9** assumption. If any non-16:9 platform choice is added,
  stretch/letterbox docs and tests change in the **same** commit — do not silently break 16:9.
- The web canvas is a fixed 16:9 region by the web plan's design, so it stays inside this
  assumption; no desktop aspect change is required for the web build.
- **Make `window/stretch/aspect="keep"` explicit** in `project.godot` (it is the unset
  default today). Cheap now, and it stops a future contributor silently switching to
  `expand` and breaking the 16:9 contract both desktop letterboxing and the web canvas rely
  on. Resolution apply path is desktop `DisplayServer` only (see effort-saving E1).

Recommendation: **accept** the 1440p/4K additions; hold the line on 16:9 for now.

### D5 — Safe-area / mobile policy: plumb margins, do not claim mobile support

Define a single **safe-area provider** (one function/property, default zero on desktop) that
HUD and menu anchoring read from — not a value sprinkled at call sites. Desktop behavior is
unchanged at zero. The web shell handles the *bottom* inset via CSS `env(safe-area-inset-*)`
outside the canvas, but a soon mobile web release will hit *in-canvas* insets (notch in
landscape, rounded corners), so route anchoring through the provider **now** even while it
returns zero. Later it gets fed from `DisplayServer.get_display_safe_area()` /
`JavaScriptBridge` with zero re-plumbing. Mobile stays **Deferred** as a platform in GDD_10
until those feeds are wired — name it that way, not "supported".

Recommendation: **accept**, with the single-provider seam (not just a default-zero value) so
the mobile feed is a one-line change later.

### D6 — Migration of saved settings

- `menu_scale_index` keeps its meaning (index into `MENU_SCALE_LEVELS`); only the apply
  mechanism changes, so existing saves need no migration.
- `hud_layout` per-panel `scale` round-trips unchanged if HUD stays on `panel.scale` (D3
  staged). If HUD migrates, `current_layout()` must still load old saved data — add a
  round-trip test.
- New resolution choices are additive; a saved `1920x1080` is unaffected.

Recommendation: **accept.** No destructive migration in v0.2.3.

## Decisions (signed off 2026-06-20)

User accepted D1-D6 on the condition they serve a mobile-friendly web release landing soon;
that lens is now baked into D2/D4/D5 and the effort-saving section below.

| Decision | Status |
| --- | --- |
| D1 renderer switch first, as its own commit | Accepted |
| D2 base-theme/metric Menu Scale (no `Control.scale` for text; `content_scale_factor` global at 1) | Accepted |
| D3 HUD scale migration now vs staged | Accepted: stage; close V021-04 only if corner snap stays stable |
| D4 add 1440p/4K, keep 16:9, make stretch aspect explicit | Accepted |
| D5 single safe-area provider seam, mobile deferred | Accepted |
| D6 no destructive save migration | Accepted |

## Effort-saving choices for the coming mobile web release

These are cheap to do now while the display code is already open, and expensive to retrofit
once a mobile-friendly web release ships. Each is scoped to a few lines / one seam — none
expand v0.2.3 into mobile support, they just stop us building the same surface twice.

| ID | Choice now (cheap) | Rework it saves later (expensive) |
| --- | --- | --- |
| **E1** | Gate the resolution apply + `DisplayConfirmDialog` confirm/revert to **desktop only** (no `DisplayServer` window resize / confirm popup on Web). | Web/mobile inheriting a meaningless resolution dropdown + a 15s confirm dialog that can't apply, then unpicking it from the shared Settings screen. |
| **E2** | Land V021-18 on **one base UI Theme** scaled at the menu root (D2), not scattered `theme_override`s. | Re-auditing every screen to add a DPI/auto-scale source when small-screen defaults are needed. |
| **E3** | While reworking minimum-size metrics in the base theme, set a **minimum touch-target size** (~44px iOS HIG floor) on interactive menu controls. | Re-touching every menu's control metrics so on-canvas buttons are tappable on the phone. |
| **E4** | Keep `get_menu_scale()` the **single source** of the applied factor; reserve room for an `"Auto"` level that derives from viewport size/DPI (don't hardcode index→factor anywhere else). | Restructuring the Menu Scale level system to add a per-device default the web build will want. |
| **E5** | Make `window/stretch/aspect="keep"` **explicit** (D4); keep `content_scale_factor` global at 1 (D2). | A contributor flipping stretch to `expand` and breaking both desktop letterboxing and the web 16:9 canvas. |
| **E6** | Route HUD/menu anchoring through the **single safe-area provider** (D5), returning zero on desktop. | Re-plumbing every anchor when the iPhone notch/home-indicator inset feed lands. |

Sequencing note: E1, E5, and the renderer switch (D1) are near-free and should ride the
earliest commits so the web track can branch off a clean, web-ready foundation. E2/E3/E6 are
naturally part of the crisp-scale rework — do them in that commit, not as a later pass.

## DoD#1 — docs to update in the implementation commits

- `GDD_01_Architecture.md` → Rendering and Display Settings (renderer = Compatibility,
  resolution list, scaling mechanism).
- `GDD_07_UI_UX.md` → Accessibility & Input Parity / Menu Scale / HUD Layout (crisp scaling,
  safe-area, touch/click default cross-ref to V021-17).
- `GDD_10_Roadmap.md` → flip `V021-18` / `V021-19` only when implemented **and** verified;
  keep V021-04 status accurate per D3.

## DoD#2 — checks to land in the same change (`AGENT/Docs/check_docs.py`)

- `RESOLUTION_CHOICES` must include `2560x1440` and `3840x2160`.
- Menu Scale must not leave modal/menu text panels with `Control.scale != 1` (the crisp
  invariant) — assert via the test seam below, and add a doc/check guard if expressible.
- `project.godot` must set `renderer/rendering_method="gl_compatibility"` (D1) and
  `window/stretch/aspect="keep"` (E5) — both are mechanical, checkable, web-load-bearing
  rules; guard them in `check_docs.py` so neither silently reverts.
- (If a checkable safe-area or touch-target rule is ratified, add its check here too.)

## Test plan

Headless (test-first where possible):

- `test_menu_scale.gd` — centered modal panels achieve the scaled visual **without**
  relying on `Control.scale != 1`; V021-08 top/bottom fit preserved at max scale;
  Action/Item/Weapon anchoring preserved.
- `test_settings_manager.gd` — `RESOLUTION_CHOICES` includes 1440p/4K; malformed → `ZERO`;
  reset → `1280x720`.
- `test_settings_screen.gd` / `test_display_confirm_flow.gd` — new choices exposed;
  confirm/revert intact.
- `test_hud_layout.gd` / `test_hud_layout_editor.gd` — only if HUD migrates (D3); else
  unchanged round-trip.
- `python3 AGENT/Docs/check_docs.py` and `TEST_JOBS=8 ./run_tests.sh` green.

Live / visual (crispness is visual; required):

- Windowed `1280x720`, `1920x1080`, `2560x1440`, `3840x2160` apply + confirm/revert.
- Menu Scale 0.75×/1.0×/1.5×/2.0× across Settings, character sheet, Map Menu, Action Menu,
  promotion/reclass, Level Up: centered, reachable, crisp text.
- Map Zoom + Menu Scale together: no forecast/HUD overlap regression.
- **Compatibility renderer desktop smoke** after D1 (touches every render path).
- **Web smoke**: text legibility at the web build's default Menu Scale on the iPhone 14 Pro;
  if crisp scaling is not yet landed, log this as a live-check risk per the web plan.

## Non-goals

- Web shell, export preset, and input bridge (owned by the web plan).
- Full gamepad support (V021-15, deferred).
- Class-skill More Info drilldown (V021-12, Polish phase).
- Declaring mobile a supported platform.
