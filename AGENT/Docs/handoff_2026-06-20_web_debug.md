# Implementation Handoff - Debug Web Playtest - 2026-06-20

Status: Planned - starts AFTER the v0.2.3 display build lands
Last verified: 2026-06-20

## Program order (decided 2026-06-20)

**The v0.2.3 display build comes first; this web build is the session after it.** v0.2.3
lands the shared foundation - Compatibility renderer (D1), explicit `stretch/aspect=keep`
(E5), crisp scaling, safe-area provider - so by the time this track starts:

- The renderer is **already** Compatibility. Slice 1 below drops the renderer change and
  becomes "Web preset + metadata tests" only. (Only redo the renderer here if v0.2.3 was
  skipped.)
- Text crispness (V021-18) is already shipped, so it is no longer a live-check risk.
- The "Current State" notes below were written before v0.2.3; re-verify them at session
  start (renderer, metadata, commit count will have moved).

Do not start this track until v0.2.3 is implemented and verified, unless explicitly asked.

## Purpose

Pick up the private iPhone 14 Pro debug Web playtest work without reopening the whole
display/accessibility backlog.

Primary plan:

- `AGENT/Docs/debug_web_playtest_plan_2026-06-20.md` - note its new top section
  "Release Infrastructure - Do First": single version source, CI build matrix, and the
  researched itch.io/`butler` automated cloud deploy + handbook delivery.

Related display handoff:

- `AGENT/Docs/handoff_2026-06-20_v0.2.3.md`

## Current State

- Branch: `code-review-followups-2026-06-17`.
- Branch is ahead of `origin/code-review-followups-2026-06-17` by 16 commits.
- Runtime metadata still says `v0.2.1`.
- No Web export preset exists yet.
- Project still advertises Forward Plus in `project.godot`; Web needs Compatibility.
- Docs and full Godot suite were green before the plan work:
  - `python3 AGENT/Docs/check_docs.py` - PASS
  - `TEST_JOBS=8 ./run_tests.sh` - PASS, 48/48 suites
- Plan commits already landed:
  - `bec8bc4` - `Plan debug web playtest build`
  - `5bb98d9` - `Session note 2026-06-20d: debug web plan`

## Decisions to Carry Forward

Use these unless the user explicitly changes direction:

- **Host:** itch.io first, not GitHub Pages.
- **Access:** unlisted/restricted/passworded itch.io page for the playtester.
- **Layout:** portrait-first emulator shell.
- **Game area:** fixed 16:9 Godot canvas.
- **Controls:** touch buttons outside the canvas; no overlap with game visuals.
- **Renderer:** switch project to Compatibility globally.
- **Web export:** single-threaded.
- **PWA:** disabled for the first pass.
- **Debug controls:** expose only F9 in a debug drawer; do not expose force-level-up or
  growth-boost toggles unless a checklist demands them.
- **Build label:** use `v0.2.3-webdebug.1` in Web checklist/build docs; do not bump the
  desktop release metadata yet unless cutting the normal desktop build too.
- **Touch default:** new Web debug settings should default `mouse_cursor` to `click`.

### Hosting Tradeoff Summary

itch.io is preferred for this first tester because it is game-hosting oriented, supports
HTML5 ZIP uploads with an `index.html`, has mobile-friendly launch behavior, and has
tester-access options. GitHub Pages is better later for CI-driven public/nightly Web
builds, but is weaker for a private one-person playtest and has less game-specific
hosting UX.

## First Implementation Slice

Recommended first commit: Web export preset + metadata tests. (Renderer switch to
Compatibility is assumed already done by the v0.2.3 build per Program order above — verify
`project.godot` has `rendering_method="gl_compatibility"` at session start; only add it here
if v0.2.3 was skipped.)

Touch:

- `export_presets.cfg`
- `project.godot` (verify renderer only; no change expected post-v0.2.3)
- `scripts/tests/test_release_metadata.gd` or a new focused Web export metadata test
- `AGENT/Docs/environment_setup.md`
- `AGENT/GDD/GDD_01_Architecture.md`
- `AGENT/GDD/GDD_10_Roadmap.md`

Expected behavior:

- Windows preset remains intact.
- New preset named `Project Prometheus Web Debug`.
- Web export path is `builds/web-debug/index.html`.
- Web preset excludes `AGENT/**`, `scripts/tests/**`, and `scripts/tools/**`.
- Web preset uses a custom HTML shell path that will become `web/debug_shell.html`.
- Project renderer is Compatibility.
- Tests assert the Web preset exists and remains aligned.

Verification for slice 1:

- `python3 AGENT/Docs/check_docs.py`
- `TEST_JOBS=8 ./run_tests.sh`
- A quick editor/headless export command if the preset can export before the shell exists;
  otherwise defer actual export to slice 2.

## Second Implementation Slice

Recommended second commit: custom HTML shell.

Add:

- `web/debug_shell.html`

Required shell behavior:

- Mobile viewport meta uses `viewport-fit=cover`.
- Page does not scroll.
- Top region contains the Godot canvas in a 16:9 frame.
- Bottom control deck is reserved outside the canvas and padded with
  `env(safe-area-inset-bottom)`.
- All buttons use stable `data-action` attributes matching Godot action names.
- A rotate-back fallback appears for landscape if portrait-only is chosen.

## Third Implementation Slice

Recommended third commit: Web input bridge.

Add:

- `scripts/web/WebInputBridge.gd`
- Focused test file for bridge action validation / stuck-button cleanup

Implementation notes:

- Load only when `OS.has_feature("web")` and custom feature `web_debug_touch` are true.
- Use `JavaScriptBridge` to receive button state from the shell.
- Route validated action names to `Input.action_press()` / `Input.action_release()`.
- Track active pointer ids so `pointercancel`, `pointerleave`, and lost touches release
  held actions.

## Build-Cut Slice

After the Web shell and bridge pass tests:

- Add `AGENT/Docs/playtest_checklist_web_debug_v0.2.3.md`.
- Export to `builds/web-debug/`.
- Zip the contents with `index.html` at the ZIP root.
- Add `AGENT/Docs/playtest_build_web_debug_v0.2.3.md` with:
  - commit SHA,
  - exported file list,
  - sizes/hashes,
  - hosting URL,
  - known caveats,
  - exact iPhone smoke result.
- Upload to itch.io as an HTML Game.
- Enable mobile-friendly behavior.
- Keep PWA off.

## Do Not Mix In

- Do not merge `main`.
- Do not cut a normal desktop `v0.2.3` release unless asked.
- Do not solve full gamepad support.
- Do not remove debug aids for a non-debug release in this slice.
- Do not call this mobile support; call it a debug Web playtest channel.

## Open Risks

- iPhone Safari may still expose Godot Web quirks even with single-thread export.
- Text crispness remains a risk until V021-18 lands; use Menu Scale and Map Zoom as the
  first workaround.
- Browser storage on iOS may not persist settings; checklist should not depend on saved
  settings.
- Itch.io page/embed settings need a real device smoke test before sending the link.

## Next Session Start

1. Read this file.
2. Read `AGENT/Docs/debug_web_playtest_plan_2026-06-20.md`.
3. Confirm the worktree is clean.
4. Implement slice 1: renderer + Web preset + metadata tests.
5. Run docs + full suite before moving to the shell.
