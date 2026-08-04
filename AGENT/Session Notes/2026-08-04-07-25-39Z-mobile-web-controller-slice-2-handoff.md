# Session Handoff - 2026-08-04 Mobile Web Controller Slice 2

## Resume point

- Product branch: `agent/from-integration/mobile-web-controller`
- Current product commit: `eb235ff2a07ea8a835da73a1ceb7be724d7a4674`
- Coordination Work ID: `MOBILE-WEB-CONTROLLER-2026-08-04`
- Detailed design: [`mobile_web_viewport_and_virtual_controller_implementation_plan_2026-08-04.md`](../Docs/plans/mobile_web_viewport_and_virtual_controller_implementation_plan_2026-08-04.md)

Slice 1 is complete: the versioned, platform-neutral `ControllerLayout` model,
six built-in combinations, orientation selection, sanitization, and viewport
clamping are committed with 13 focused assertions and the full 117-suite run
green.

## Next implementation slice

Continue with Slice 2, global input and renderer:

1. Add a persistent controller service with open action descriptors and
   press/release reference counting. Release held actions on cancel, blur,
   visibility loss, layout/profile changes, and editor entry.
2. Bridge validated layout/action data to the web shell. Render both the
   rebind-aware virtual-gamepad profile and fixed-semantics labeled-actions
   profile; do not synthesize a browser Gamepad device.
3. Make controller hit surfaces capture and stop their own pointer streams while
   unrelated touches continue to the Godot canvas. Editing mode captures every
   pointer and pauses gameplay.
4. Add simultaneous canvas/controller multi-touch, held-action cleanup, duplicate
   press reference-counting, profile swap, and campaign-safe allow-list tests.
5. Re-run the Playwright browser matrix in portrait and landscape before starting
   the two Settings editors.

## Path and sequencing constraints

- Re-check `coordination/tasks.json` before claiming `tools/web/pwa_shell.html`,
  export presets, `InputModeManager`, or the safe-area service; those paths were
  deliberately left untouched in Slice 1 because other active tasks owned them.
- Keep presentation replaceable through validated theme data. Campaign content
  may supply appearance only, never actions, JavaScript, CSS, or executable
  resources.
- Preserve the default minimal-black renderer and the Pack 0 Kenney CC0 asset
  seam for the later campaign-theme slice.
- Use the canonical docs-line claim workflow before pushing new feature commits:
  `scripts/agent-work --repo Project_Prometheus claim --commit HEAD` followed by
  `scripts/agent-work --repo Project_Prometheus push`.

## Acceptance boundary

Slice 2 is complete when both profiles work throughout the game, controller
pointers cannot leak accidental canvas input, non-controller canvas touches still
work concurrently, every held action is released across lifecycle transitions,
and focused Godot plus Playwright tests pass. Presets/free dragging, six-slot
persistence UI, transparency/size editing, and campaign themes remain later slices.
