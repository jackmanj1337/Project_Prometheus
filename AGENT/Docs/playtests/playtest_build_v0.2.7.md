---
Role: dated
---

# Playtester Build Manifest - v0.2.7

> **Status:** exported 2026-07-05. Windows debug `.exe` built with Godot `4.6.stable`;
> the release metadata (`export_presets.cfg`, Main Menu `VersionLabel`,
> `environment_setup.md`) is at `v0.2.7`.

## Artifact

- Path: `builds/Project_Prometheus_v0.2.7_debug.exe`
- Source commit: `26af9f4`
- Baked build stamp (`build_info.json`): version `0.2.7`, commit `26af9f4`,
  built_at `2026-07-05T00:47:01Z`
- Exported: `2026-07-05`
- Godot: `4.6.stable.official.89cea1439`
- Size: `101297072` bytes
- SHA-256: `5c02a0c8c668ceb2f241b05872d0e74d0e9f7e0898157c43478601eb610c5aed`

The artifact is intentionally ignored by Git. v0.2.7 ships as **two files**: the
executable and the single self-contained handbook
`AGENT/Docs/playtests/playtest_checklist_v0.2.7.md`. **The `._sc_` self-contained marker
is no longer shipped** — exported Godot builds ignore it (proven by the v0.2.6 return),
so the log lands in the OS user-data dir (`%APPDATA%`), not beside the exe. The startup
BUILD STAMP's `log=` line reports the exact path.

## Why v0.2.7

v0.2.7 is the **rerun build** that closes the display gate (`VAL-V023-DISPLAY`) after the
v0.2.6 return. The owner walked the v0.2.6 triage review Q1-Q7 (2026-07-05) and the
buildable decisions landed here. Most of the v0.2.6 handbook already **PASSED** on the
return (§1.2, §1.7, all of Part II, the Part III regression pass); this build re-checks
only the remaining/newly-fixed display-gate items — §1.1, §1.3, §1.4, §1.5, §1.6.
`VAL-V023-DISPLAY` flips only when this build's Part I passes on a real Windows screen.

## What changed since v0.2.6

Each maps to a Part I check in the handbook, or to a review-question decision.

- **Portable-log strategy corrected (`V026-08`, review Q3, §3.2):** dropped the `._sc_`
  self-contained marker from `prepare_build.sh` and the ship list — exported Godot ignores
  it. `%APPDATA%\Godot\app_userdata\Fire Emblem RPG\logs\godot.log` is now the documented
  primary location, and the BUILD STAMP's `log=` line is authoritative. Fixed the
  misleading "next to the exe" comments in `BuildInfo.gd` / `Boot.gd` and both guide docs.
- **Promotion / reclass picker sizing (`V026-05a`, review Q4, §1.5):** the authored panel
  size was raised (Promotion 760×500 → 840×760, Reclass 640×550 → 840×760, capped to the
  viewport) so at **2.0×** Menu Scale at least one full class option fits the frame. The
  `follow_focus` fix from v0.2.6 (`V026-05c`) keeps the keyboard-focused option in view.
- **Handbook asks (`V026-01d/e`, review Q1, §1.1):** the checklist asks the tester to
  finish the truncated v0.2.6 sentence about the 0.5×→2.0× centering recurrence and to pin
  down the unreproduced "flickers near the border" report with an exact pointer position.
- **Resolution/window-mode explainer (`V026-06`, review Q7, §1.6):** a half-page digest of
  `display_and_settings_guide.md` (Resolution = Windowed only; request→clamp→applied
  readout; OS drag-resize writes back the applied size) added to the §1.6 preamble.

The mechanical V026 fixes themselves (first-apply centering `V026-01a`, scrollbar margin
`V026-01b`, hotseat debug row `V026-01c`, stale-canvas-transform flush `V026-03/04a`,
forecast dash rows `V026-04b`, promotion `follow_focus` `V026-05c`) landed on the v0.2.6
return day and are carried into this build for the live re-verify.

## Deferred / not in this build

- **Character-sheet Back-button keyboard access (`V026-02e`, review Q2→C):** deferred to
  the shared `B6-INPUT` selector-focus extraction; Back stays reachable via X/Esc/right-
  click. Not built here.
- **Recoverable auto-promotion action (`V026-05b`, review Q5→A):** a free re-open-picker
  action is recorded as a requirement on the `B2-ACTION-EFFECT` / `[SAC]` registry, not
  hardcoded into ActionMenu. Not built here.
- **Victory-waits-for-progression sequencing (`V026-05d`, review Q6→A):** its own control-
  plane slice (`B5-VICTORY-PROGRESSION-SEQ`); explicitly NOT a display-gate item.
- **Promotion-picker master/detail redesign** and the **paged character sheet** remain with
  the `UI-INSPECTION` pass.

## Known limitations carried into this build

- **This build IS the validation vehicle.** Every repair above is visual/input and was
  verified with headless structural / event-routing tests; `VAL-V023-DISPLAY` flips only
  after the handbook's Part I passes on a real Windows screen (ideally incl. 1440p/4K).
- **Input-routing / anchoring fixes need a live pass.** Headless GUI picking differs from
  desktop, so the high-zoom context-menu (§1.3) and combat-forecast (§1.4) anchoring and
  the picker sizing (§1.5) were proven by structural tests, not a real desktop render —
  confirm them live.
- **Log return is still the top ask.** The BUILD STAMP is proven; the `%APPDATA%` path was
  the flow that finally worked on the v0.2.6 return — §3.2 now documents it directly.

## Verification

- Full source suite: PASS (49 suites green; pre-commit hook gates it).
- check_docs: PASS (21/21).
- Release-metadata test (`test_release_metadata.gd`): PASS — preset name/path/product
  version, Main Menu label, checklist presence, and setup guide all agree at `v0.2.7`.
- Export: PASS — Windows debug `.exe` built headless; `res://build_info.json` confirmed
  packed (version `0.2.7`, commit `26af9f4`); SHA-256 + size recorded above.
- No `._sc_` marker produced (confirmed post-`prepare_build.sh`).
- All visual/input checks remain in `playtest_checklist_v0.2.7.md` and need a human pass
  on real Windows (Part I is the v0.2.3/v0.2.5/v0.2.6 display closeout gate).
