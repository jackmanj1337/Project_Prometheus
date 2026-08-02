# v0.6.1 Windows Verification Checklist

## Build identity

- [ ] `Project_Prometheus_v0.6.1_debug.exe` matches `SHA256SUMS.txt`.
- [ ] Main Menu shows `v0.6.1`; startup BUILD STAMP matches `BUILD_INFO.json`.
- [ ] Tester bundle includes the labeled Playwright screenshot album and `report.json`.

## Responsive UI

- [ ] Review centered menus at 1280×720, 1280×800, 1365×768, 1920×1080,
  2560×1440, and 3840×2160.
- [ ] At 2× menu/content scale, New Game scrolls; Unit Details stacks its regions;
  Results stacks report/actions; no centered frame leaves the safe viewport.
- [ ] Verify non-zero safe-area padding and HUD panel attachment/clamping.
- [ ] Confirm contextual action, attack-preview, weapon, item, and map menus remain
  anchored to gameplay rather than being forced to screen center.

## Input and stability

- [ ] Repeat keyboard, mouse, and controller navigation across every menu.
- [ ] Exercise FileDialog filename editing and Escape ownership.
- [ ] Repeat controller attacks, level-ups, end-turn confirmation, and menu transitions;
  attach the structured `TRANSITION` log if a lockout recurs.
- [ ] Complete a representative map without a crash or stuck modal.

## Campaign and save carry-forward

- [ ] Launch both bundled campaign packages and confirm expected factions spawn.
- [ ] Load existing v0.6.0 saves with their campaign packages installed.
- [ ] Confirm a missing campaign package blocks restore without changing the save.
  More helpful recovery wording is deliberately deferred to the associated plan.

## Result

- Tester / host:
- Date:
- PASS / FAIL:
- Notes and screenshot references:
