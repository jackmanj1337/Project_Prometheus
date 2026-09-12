---
Role: dated
Type: playtest
Status: Ready
Last verified: 2026-08-11
---

# v0.7.6 Windows Tester Checklist

Return this completed checklist plus the full Godot log directory. Use a fresh user-data
directory for section 1, then keep that directory for the remaining sections.

## 1. Build identity and first-run import

- [x] Both logs begin with BUILD STAMP version `0.7.6` and the commit recorded in `BUILD_INFO.json`.
- [x] With clean user data, New Game reads `New Game (No Data Packs Installed)` and is disabled.
- [x] Campaign Library remains enabled and imports the supplied pack ZIP.
- [x] Import immediately enables New Game without restart.
- [x] The imported campaign appears and launches its first map.

## 2. Installed versions and failure isolation

- [x] Install both supplied versions of the migration fixture; both appear side-by-side with versions.
- [x] Each row launches the exact selected version.
- [x] Import the supplied development-only/no-playable fixture; it reports `no_playable_campaign` and is not installed.
- [x] A failed activation leaves the previously selected package playable.
I think this looks good, however, I cant tell if the two different versions are different in practice.
## 3. Native transfer ownership

- [x] Campaign-pack import opens one Windows-owned file picker.
- [x] Campaign-pack export opens one Windows-owned Save dialog with `<package-id>-<version>.zip` editable.
- [x] Save import/export and status import also use one native picker each.
- [x] Cancel/Escape closes only the picker, writes or overwrites nothing, and restores focus to its invoking button.
- [x] After cancel and after success, keyboard/controller navigation resumes normally.

## 4. Direct save migration

- [x] A save from fixture version 1.0.0 offers `Import into 2.0.0` only on the declared destination.
- [x] Preview/success maps campaign, node, map, unit, item, class, and skill references and creates a new slot.
- [x] The source slot remains present and loadable under version 1.0.0.
- [ ] Unmapped destination ids, ambiguous aliases, topology changes, corrupt source data, and a failed commit create no migrated slot and do not alter the source.
	- not sure how to test this
- [ ] Cross-package and chained/automatic-newest migration are not offered.
	- not sure how to test this, but likely good.


## 5. Web transfer

- [x] In the supplied Web build, campaign/save import uses the browser upload picker.
- [x] Campaign/save export downloads byte-valid ZIP/JSON with the suggested name.
- [ ] Browser cancel is silent and returns focus; no staged transfer file remains.
browser cancel is fine, but I think that when a download was canceled then the 
## 6. Campaign regression

- [x] Save, quit, relaunch, and Continue restore the package-backed campaign.
- [x] Complete one representative map and reach its result screen.
- [x] No duplicate-signal, stuck-modal, input-leakage, focus-loss, or package-activation errors appear in returned logs.

Checked suspend and quit and reload and attempted to continue. Initial attempt failed but a immediate follow up attempt succeeded.

## Tester notes

- Windows version:
- Controller model (if used):
- Findings/screenshots:
All problems found are already known and scheduled to be fixed later. We should likely accept this build and work on the release cycle.