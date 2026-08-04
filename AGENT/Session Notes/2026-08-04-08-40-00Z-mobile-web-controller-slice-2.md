# Session Note - 2026-08-04 Mobile Web Controller Slice 2

## Branch context

- Branch: `agent/from-integration/mobile-web-controller`
- Base branch: `agent/integration`
- Base SHA: `cd7797fe0985999bac16fd4c6b46e1e299c580fe`
- Coordination Work ID: `MOBILE-WEB-CONTROLLER-2026-08-04`
- Plan: `AGENT/Docs/plans/mobile_web_viewport_and_virtual_controller_implementation_plan_2026-08-04.md`
  (docs line only — `docs-guard` fences `AGENT/Docs/plans/**` off this branch)

## What was done

Slice 2, global input and renderer. Slice 1 left a pure layout model with no
consumer; this makes it drive real input.

- `ControllerActionRegistry` — the open descriptor registry (12 virtual-gamepad
  elements, 9 labeled actions). It is the only id→action map anywhere in the
  feature, which is what makes the bridge safe: saved layouts and the shell
  address elements by **id**, never by action, so neither a tampered save nor a
  compromised page can fire an action nobody registered. Adding a control is an
  entry, not a `match` arm.
- `ControllerPressLedger` — reference-counted presses, kept pure so the entire
  stuck-input surface is testable headlessly. Two fingers on one action release
  it once; a pointer sliding between controls releases the first.
- `ControllerService` — the autoload. Both profiles, orientation selection, and
  **one** release path shared by focus loss, backgrounding, close, rotation,
  profile change, combination change, and editor entry. `PROCESS_MODE_ALWAYS`,
  so a paused tree still releases.
- `ControllerWebBridge` — the JS seam. Message parsing and dispatch are static
  and pure, so the protocol (including every fail-closed path) is covered
  without a browser.
- `tools/web/controller_shell.js` — the DOM renderer, dependency-free and
  CSP-compatible (CSSOM only, no `eval`, no inline `<style>`, no remote fetch).

Two behaviours worth recording because they are easy to get wrong:

1. **The virtual pad's glyph is resolved from the live binding, not stored.**
   `InputDisplay.first_pad_label_for_action()` already existed for prompt
   swapping, so rebinding Confirm from A to B relabels the control without
   moving it. Labeled actions deliberately get no glyph — their whole point is
   that a physical rebinding never rewords them.
2. **A resize is not a rotation.** The first draft released every held action on
   `resize`. Mobile browsers fire that continuously as the URL bar collapses, so
   it would have dropped a press mid-play on every scroll. Only a real
   orientation flip now reports.

### Deliberately not done

- **No shell wiring.** `tools/web/pwa_shell.html` and `scripts/tools/prepare_build.sh`
  are claimed by `PWA-PLAYTEST-HOSTING-2026-08-03` (in_review) and do not exist
  on this branch. The renderer is written as a standalone module: the shell needs
  one `<script src="controller_shell.js">` (or the exported-resource fallback in
  `ControllerWebBridge.SHELL_SCRIPT_PATH`) at merge time, and nothing else.
- **No `InputModeManager` change.** `MODE_TOUCH` is still gated on
  `OS.has_feature("mobile")`, which is false on web — that is
  `MOBILE-WEB-UX-GAPS-2026-08-03`'s claimed path, item 2.1 of the PWA handoff.
  The controller works regardless, because it presses InputMap actions directly
  rather than depending on the active input mode.
- **No replacement of the map-local overlay.** `scripts/ui/TouchControls.gd` and
  `scripts/core/MapCursor.gd` belong to `DEDICATED-TOUCH-CONTROLS-2026-08-03`
  (in_review) and are not on this branch. The service is the thing that replaces
  it; the deletion happens when those branches meet.
- **No Playwright run against a real export.** The web export preset lives on
  `FIX-WEB-EXPORT-PRESET-2026-07-31` (in_review) and is not on this branch, so
  there is nothing to export. The renderer is instead covered directly in
  Chromium, which tests the part an export run would not isolate anyway.

## Commits claimed

- `631d38a6493a8ea7e4714e27cffa2f42a5a91829` — Add the persistent on-screen controller service and browser renderer

## Gates

- `scripts/tests/test_controller_service.gd`: PASS, 45 assertions.
- `bash run_tests.sh`: PASS, all suites green (118 with the new one).
- `node tools/web/controller_shell.test.mjs`: PASS, 28 assertions in real
  Chromium — including two simultaneous CDP touch points, which is the only way
  to prove a control touch and a canvas touch coexist.
- `gdformat` / `gdlint`: PASS.
- Documentation, RNG, scene-integrity, analyzer, uid and evidence hooks: PASS.

## Traps paid for here

- **The uid guard is repo-state, not commit-scope.** While any `.gd.uid` sidecar
  is untracked, *no* commit succeeds — so a change that adds several scripts
  cannot be split into separate commits until every sidecar is staged.
- **The two claims checkers disagree by lineage.** The canonical checker on
  `agent/staging-area` reads claims only from `refs/remotes/origin/agent/staging-area`.
  Branches off `agent/integration` — like this one — have ~90 ancestors whose
  notes live on the integration line, so adopting it here fails all of them. The
  old working-tree checker is the correct one for this lineage. Do not "upgrade"
  it on an integration-descended branch.
- Consequently the Slice 1 note is **carried** onto this branch as
  `2026-08-04-05-48-31Z-mobile-web-controller-slice-1.md` (the timestamped form
  check 43 demands). It duplicates the docs-line copy; one of the two must be
  deleted when this branch merges toward the docs line, or `eb235ff2` ends up
  claimed twice.

## Next

Slice 3, the Game View submenu (presets, free editor, aspect lock, guides,
Undo/Reset, persistence) — but two things should land first:

1. **Merge `PWA-PLAYTEST-HOSTING-2026-08-03` forward**, then add the one-line
   shell include. Until then the renderer ships untested against a real export.
2. **Persistence.** The service builds its combinations from
   `ControllerLayout.default_collection()` every boot; nothing saves them yet.
   `SettingsManager.gd` is claimed by two active rows
   (`IMPL-FILEDIALOG-ESCAPE-TEXTINPUT`, `IMPL-VIEWPORT-ANCHORING`), so this
   needs those to land or an explicit hand-off of the path.

Owner call still open from the plan: whether the Slice 4 editor edits elements
in the DOM (shell-side drag) or in an in-engine Control. The service supports
either — `set_editing(true)` already captures every pointer and pauses input.
