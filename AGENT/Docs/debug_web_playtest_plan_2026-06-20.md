# Debug Web Playtest Plan - iPhone 14 Pro - 2026-06-20

Status: Target design - ready for implementation after decision signoff
Last verified: 2026-06-20

## Purpose

Ship a debug Web build that one playtester can open on an iPhone 14 Pro without
installing an app. This is a private playtest channel, not a public release.

The first pass uses a mobile-emulator style layout:

- A fixed 16:9 Godot canvas acts as the game screen.
- Touch controls live outside the canvas, in reserved device-screen space.
- Buttons never overlap game visuals.
- The build stays debug-labeled and may keep debug-only aids that are gated by
  `OS.is_debug_build()`.

## Release Infrastructure - Do First (added 2026-06-20)

Land these before/around the manual build-cut so multi-platform releases do not stay manual.
Items 1-2 are not web-specific, but the web release is the forcing function that makes them
worth doing now. Item 3 is the researched cloud-deploy recommendation.

### 1. Single version source

Collapse the three hand-synced version strings - `export_presets.cfg`,
`MainMenu.tscn` `VersionLabel`, `environment_setup.md` - into one source of truth (a
`Version.gd` const or a `version.txt`) that all three read. This kills the desktop vs
`v0.2.3-webdebug.1` drift risk called out in the hosting decisions below. `test_release_metadata.gd`
then asserts the readers match the source instead of asserting three literals.

### 2. CI build matrix (automated export)

A GitHub Actions workflow that exports Windows + Web from one commit, runs
`./run_tests.sh` + `check_docs.py`, hashes the artifacts, and fills the build manifest.
This replaces the manual headless-export / SHA / manifest dance exactly when going
multi-platform makes it most error-prone.

- Use the `abarichello/godot-ci` Docker image (Godot engine + export templates baked in) -
  the de-facto Godot CI image.
- Matrix over `[windows, web]` referencing the named presets from `export_presets.cfg`
  (quote preset names that contain spaces, e.g. `"Project Prometheus Web Debug"`).
- `export_presets.cfg` must be committed (it is).

### 3. Automated cloud deploy + handbook (researched recommendation)

Recommended stack: **itch.io via `butler` inside the same GitHub Actions workflow.** This is
the de-facto standard for Godot HTML5 playtest distribution and matches the existing
itch.io-first hosting decision.

- **Pipeline:** `abarichello/godot-ci` exports the Web preset, then
  `butler push builds/web-debug <itch-user>/<game>:web-debug`.
- **Secrets:** `BUTLER_API_KEY` (from the itch.io API-keys page - a dedicated butler key,
  not the generic API key), plus the itch username + game slug.
- **One-time manual itch setup:** set the page type to HTML embed and tag the channel
  "HTML5 / Playable in browser"; set the page to unlisted/restricted/password for the
  single tester; enable mobile-friendly. After that, re-pushing the **same channel** updates
  the embed in place - the tester's link never changes.
- **Single-thread payoff:** the already-chosen single-threaded export avoids the
  SharedArrayBuffer COOP/COEP cross-origin-isolation requirement, so itch hosting works
  without the per-game SharedArrayBuffer header toggle. This validates the single-thread
  decision - keep it.
- **Handbook alongside:** keep the HTML5 embed channel game-only. Publish
  `playtest_checklist_web_debug_v0.2.3.md` via the workflow's **GitHub Release** (attach the
  `.md`/PDF) and link it from the itch page description - one tester link for the game, one
  for the handbook. (Alternative: a separate butler channel such as `web-debug-handbook` for
  a downloadable; the Release is simpler for one tester.)
- **Alternative host:** `abarichello/godot-ci` also templates GitHub Pages deploy
  (`gh-pages` branch + deploy token). Keep it as the documented second choice - better later
  for public/nightly Web builds, weaker for a private one-tester playtest.

References: `abarichello/godot-ci` (GitHub Actions + Docker image, itch.io/GitHub Pages
templates); itch.io butler manual "Pushing builds" (channel semantics + HTML5 tagging).

## Target Platform

Primary target:

- iPhone 14 Pro
- Safari
- Portrait orientation for the first pass
- HTTPS hosted page, shared only with the playtester

Secondary smoke targets:

- Desktop Chromium or Firefox for quick Web startup checks.
- Desktop Safari if available, because iPhone Safari is the highest-risk browser.

Known engine constraints from Godot Web export docs:

- Web export needs the Compatibility renderer.
- Forward+ and Mobile renderers are not supported on Web.
- Use a single-threaded Web export for this debug pass.
- Do not depend on browser persistence; iOS private browsing and browser storage
  settings can prevent `user://` persistence.

## Locked Implementation Defaults

These defaults are chosen to keep the first playtest build small and reversible.

### Export Shape

- Add a second export preset named `Project Prometheus Web Debug`.
- Export path: `builds/web-debug/index.html`.
- Use debug export: `godot --headless --export-debug "Project Prometheus Web Debug" builds/web-debug/index.html`.
- Keep the Windows preset until the normal desktop playtest flow is replaced.
- Exclude the same development-only paths as the Windows preset:
  `AGENT/**`, `scripts/tests/**`, `scripts/tools/**`.
- Single-threaded export.
- PWA disabled for the first pass to avoid service-worker cache confusion during
  rapid playtest iteration.

### Renderer

- Switch the project to Compatibility unless a quick spike proves a web-only
  export override is safer.
- Re-run the full suite after the renderer switch.
- Live-smoke the Windows/debug desktop build once after the switch, because this
  touches every render path even if the game is mostly 2D.

### Emulator Shell

Use a custom Web HTML shell for physical phone layout.

Reasoning:

- The HTML page can reserve separate regions for the game screen and controls.
- Godot sees only the canvas area as its viewport, so existing HUD/menu code does
  not need to understand the control deck.
- Touch buttons are outside the canvas, so overlap is impossible by layout.

Recommended file:

- `web/debug_shell.html`

Layout:

- `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`
- Page background: solid black or dark neutral.
- Top region: centered 16:9 game canvas, full available width.
- Bottom region: fixed touch-control deck with `padding-bottom:
  env(safe-area-inset-bottom)`.
- Disable page scrolling and browser gestures on the control deck with CSS
  `touch-action: none`.

### Input Bridge

Do not rely on synthetic keyboard events from JavaScript.

Implement a Godot-side Web input bridge:

- Recommended file: `scripts/web/WebInputBridge.gd`.
- Load it only for Web debug builds, using `OS.has_feature("web")` plus a custom
  export feature such as `web_debug_touch`.
- Expose a JavaScript callback through `JavaScriptBridge`.
- The HTML shell calls the bridge with action names and pressed/released state.
- The bridge calls `Input.action_press(action)` and `Input.action_release(action)`.

This keeps every touch button mapped to the same action names that keyboard and
mouse already use.

### First-Pass Button Deck

The button set should cover the existing keyboard/mouse playtest checklist without
requiring browser keyboard input.

| Deck area | Label | Action |
| --- | --- | --- |
| Left D-pad | Up / Down / Left / Right | `cursor_up`, `cursor_down`, `cursor_left`, `cursor_right` |
| Right face | A | `confirm` |
| Right face | B | `cancel` |
| Center | Menu | `open_menu` |
| Center | Info | `inspect_unit` |
| Center | More | `more_info` |
| Center | Danger | `show_danger_zone` |
| Center | Settings | `open_settings` |
| Shoulder row | L / R | `prev_unit`, `next_unit` |
| Shoulder row | - / + / 0 | `zoom_out`, `zoom_in`, `zoom_reset` |
| Debug drawer | F9 | `debug_toggle_hotseat_override` |

Do not expose force-level-up or growth-boost debug toggles on the first Web build
unless the checklist explicitly needs them.

### Touch Behavior

- Pointer down presses the mapped action.
- Pointer up, pointer cancel, and pointer leave release it.
- D-pad buttons may repeat by holding the action down; use the existing action
  repeat path before adding custom repeat timers.
- Prevent multi-touch from sticking actions: each button tracks its active pointer
  id and releases on cancel/leave.
- The canvas itself still accepts normal Godot click/touch input, so V021-17 click
  cursor mode remains available.

## Implementation Order

1. **Renderer and export preset**
   - Change renderer to Compatibility or prove a web-only override works.
   - Add the Web debug export preset.
   - Add a metadata test that validates the Web preset exists, exports to
     `builds/web-debug/index.html`, excludes dev paths, and uses the debug shell.

2. **HTML shell**
   - Add `web/debug_shell.html`.
   - Reserve canvas and control-deck regions.
   - Add touch buttons with stable `data-action` attributes.
   - Add a small startup fallback message for non-Web or bridge-not-ready cases.

3. **Web input bridge**
   - Add `scripts/web/WebInputBridge.gd`.
   - Register JavaScript callbacks only on Web.
   - Route button down/up to `Input.action_press/release`.
   - Add focused tests around action validation and stuck-button cleanup using a
     test seam instead of requiring a browser.

4. **Mobile playtest defaults**
   - On Web debug builds, default `mouse_cursor` to `click` for new settings files.
   - Leave existing saved settings alone.
   - Add a Settings row note in the playtest checklist so the tester can switch
     between `Click` and `Follow` if needed.

5. **Build docs and checklist**
   - Add `AGENT/Docs/playtest_checklist_web_debug_v0.2.3.md`.
   - Add `AGENT/Docs/playtest_build_web_debug_v0.2.3.md` after export with commit,
     file list, size/hash, host URL, and known caveats.
   - Update `AGENT/Docs/environment_setup.md` with Web export commands after the
     preset lands.

6. **Export and host**
   - Export to `builds/web-debug/`.
   - Zip the directory for hosting.
   - Host as a private/unlisted itch.io HTML5 page unless another host is chosen.
   - Load once on desktop, then on the iPhone 14 Pro.

## Verification

Headless:

- `python3 AGENT/Docs/check_docs.py`
- `TEST_JOBS=8 ./run_tests.sh`
- Focused tests for:
  - Web export metadata
  - Web input bridge action validation
  - Button stuck-state cleanup
  - Settings default for Web debug `mouse_cursor`

Desktop Web smoke:

- Page loads from a local server or draft host.
- No browser-console startup errors.
- Canvas has a 16:9 game region.
- Buttons are visible below the game region.
- Buttons trigger the matching in-game actions.
- Reloading does not show stale service-worker content.

iPhone 14 Pro smoke:

- Page opens in Safari over HTTPS.
- Game canvas is fully visible and not covered by controls.
- Bottom controls stay above the iPhone safe-area inset.
- D-pad, A, B, Menu, Info, More, Danger, Settings, and Zoom work.
- Terrain More Info paging works through the More button and canvas click mode.
- Character sheet is readable enough at the selected Menu Scale.
- Map zoom can make units/tile text inspectable.
- Rotating the phone either keeps a usable layout or shows a clear rotate-back
  fallback.

## Known Non-Goals

- This does not make mobile a full platform target.
- This does not solve full gamepad support.
- This does not remove debug aids required before a non-debug release.
- This does not add PWA/offline install support.
- This does not solve iOS native export.

## Decisions Still Needed

The plan is implementation-ready if these recommendations are accepted.

| Decision | Recommendation | Why |
| --- | --- | --- |
| Hosting target | Use an unlisted/passworded itch.io HTML5 page. | It is simple for one playtester and avoids repo-public GitHub Pages setup. |
| Orientation | Portrait-first emulator shell; landscape can show a rotate-back message in pass 1. | Matches the requested Game Boy emulator model and keeps controls below the canvas. |
| Renderer scope | Switch the project to Compatibility globally. | The roadmap already ratified Compatibility for Web and says Forward+ is not needed. |
| PWA | Off for the first debug pass. | Avoids service-worker cache bugs while iteration is fast. |
| Thread support | Off. | Avoids cross-origin isolation headers and reduces hosting risk. |
| Debug controls | Expose only F9 in a debug drawer. | Useful for hotseat retests without exposing unrelated force/growth debug aids. |
| Build label | Use `v0.2.3-webdebug.1` in the checklist/build manifest, not as the desktop release version. | Keeps this private Web channel distinct from normal Windows playtest tags. |
| Touch defaults | New Web debug settings default to `mouse_cursor = "click"`. | Touch hover does not exist; click mode is the deliberate mobile path already built in V021-17. |

## Handoff Notes

- Pair this with the v0.2.3 display work if possible; both touch renderer/display
  assumptions.
- If schedule is tight, ship the Web debug shell before crisp Menu Scale, but mark
  text crispness/readability as a live-check risk in the checklist.
- Do not call this mobile support in release notes. Call it a debug Web playtest
  channel.
