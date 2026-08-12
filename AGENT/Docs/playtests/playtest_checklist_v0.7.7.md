---
Type: playtest
Status: Ready
Last verified: 2026-08-12
---

# v0.7.7 Focused Windows Tester Checklist

This is a narrow recheck of the cold-start Continue repair found in the v0.7.6
return. The rest of that Windows/browser round remains valid evidence and should not
be repeated unless this candidate exposes another finding. Return this checklist and
the complete Godot log directory.

## Build identity

- [ ] The log begins with BUILD STAMP version `0.7.7` and the commit recorded in
  `BUILD_INFO.json`.
- [ ] The release executable, debug executable, and Web archive match the supplied
  checksums.

## First-attempt Continue from inactive startup

- [ ] Start with the supplied migration pack installed and create either a campaign
  save or a mid-map suspend under version 2.0.0.
- [ ] Quit the executable completely, then relaunch it. Do not open Campaign Library
  or New Game before continuing.
- [ ] Press Continue exactly once. It restores the saved campaign or battle without
  showing `Could not load the campaign save` or requiring a second attempt.
- [ ] The returned log contains the expected `campaign_restored` and node launch or
  resume context for `v076_migration_fixture` version `2.0.0`.
- [ ] The returned log contains neither `DataManager: save has no campaign package
  identity` nor `SaveData: prior campaign content could not be restored after
  validation`.

## Regression smoke

- [ ] Quit and relaunch once more; first-attempt Continue succeeds again.
- [ ] Campaign Library still lists both supplied migration-fixture versions.
- [ ] No duplicate-signal, stuck-modal, input-leakage, focus-loss, or package-
  activation errors appear in the returned log.

## Tester notes

- Windows version:
- Controller model (if used):
- Findings/screenshots:
