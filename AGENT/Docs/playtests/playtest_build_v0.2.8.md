# Playtester Build Manifest - v0.2.8

> **Status:** exported 2026-07-05. Windows debug `.exe` built with Godot `4.6.stable`;
> the release metadata (`export_presets.cfg`, Main Menu `VersionLabel`,
> `environment_setup.md`) is at `v0.2.8`.

## Artifact

- Path: `builds/Project_Prometheus_v0.2.8_debug.exe`
- Source commit: `ab81a21`
- Baked build stamp (`build_info.json`): version `0.2.8`, commit `ab81a21`,
  built_at `2026-07-05T22:45:47Z`
- Exported: `2026-07-05`
- Godot: `4.6.stable.official.89cea1439`
- Size: `101301264` bytes
- SHA-256: `850c5f87a19a3ef6e861f4149d746239e6cdb8cfecb32ff8951418fcd2de53e5`

The artifact is intentionally ignored by Git. v0.2.8 ships as **two files**: the
executable and the single self-contained handbook
`AGENT/Docs/playtests/playtest_checklist_v0.2.8.md`. No `._sc_` marker (dropped in
v0.2.7); the log lands in the OS user-data dir (`%APPDATA%`) and the startup BUILD
STAMP's `log=` line reports the exact path — that flow worked on the v0.2.7 return.

## Why v0.2.8

v0.2.8 is the **second display-gate rerun** (`VAL-V023-DISPLAY`). The v0.2.7 return
(2026-07-05) passed §1.1 Menu Scale and §1.5 promotion picker live and returned a clean
regression + log, but **§1.3, §1.4 and §1.6 failed** with new, specific defects
(triage: `playtest_v0.2.7_results_triage_plan_2026-07-05.md`). The owner walked review
Q1-Q7 the same day and the full V027 fix pass landed on this branch
(`5446882..750690f`, one commit per fix, each with regression tests). This is a **pure
rerun build** — it carries the Q1-Q6 fixes and no feature work; Part I of the handbook
is §1.3/§1.4/§1.6 only. `VAL-V023-DISPLAY` flips only when those three pass on a real
Windows screen.

## What changed since v0.2.7

Each maps to a Part I check in the v0.2.8 handbook.

- **Action-menu far-edge anchor (`V027-02`, review Q1, §1.3):** `MapCursor._place_menu_near`
  now offsets from the zoomed tile's **far edge plus a constant gap** (the AttackPreview
  model) instead of the V025-03 capped whole-offset, which had left the menu drifting
  progressively **over** the unit as zoom rose past 1×. Regression test asserts far-edge
  placement at 1× and 4×.
- **Forecast first-open sizing (`V027-03a`, review Q2, §1.4a):** `show_preview` re-runs
  sizing + placement one frame after every show (panel held transparent for that frame),
  eliminating the first-open dead space caused by inflated first-layout content minimums.
- **Forecast wall placement (`V027-03b`, review Q3, §1.4b):** the headless wall-sweep
  repro found the real root cause — `keep_cursor_in_view` was the one camera write
  without `_flush_scroll()`, so a placement in the same frame as a cursor-driven scroll
  read a stale canvas transform (wall-agnostic; the tester saw it at the left wall). Fixed
  with the flush, plus a belt-and-braces **deferred one-frame re-anchor** after zoom/scroll
  repositions — the automated version of the tester's manual "zoom past max" heal.
- **Menu Scale re-apply on resize (`V027-04a`, review Q4, §1.6-1):** `SettingsManager`
  connects viewport `size_changed` → a deferred, coalesced `_apply_menu_scale()`, fixing
  the once-per-boot Settings-menu stretch after a windowed 1440p→4K switch at 2.0×.
- **OS drag-resize write-back (`V027-04b`, review Q5→B, §1.6-2):** an OS resize while
  windowed **writes the actual client size back into the saved Resolution setting**
  (persists immediately); non-preset sizes render as a trailing display-only
  **`Custom (WxH)`** dropdown entry; programmatic resizes are excluded so a clamped
  request never self-overwrites. **No drag-triggered re-centre** — the v0.2.7 handbook's
  re-centre claim was wrong and the §1.6 explainer is corrected in this handbook.
- **Resolution gray-out outside Windowed (`V027-05c`, review Q6, §1.6-3):** in
  Borderless/Fullscreen the Resolution dropdown is disabled and the readout pins to
  `native WxH`; the saved request survives and the row re-enables intact on returning to
  Windowed.

Not display-gate but on this branch and in this build: `B5-VICTORY-PROGRESSION-SEQ`
(victory presentation waits for the level-up/promotion queue to drain, review Q6 of the
v0.2.6 walk, commit `9ff2e2f`) — covered by §3.1 regression only.

## Deferred / not in this build

- **§1.1 frame-size stability across Menu Scale factors (`V027-01`) and the MainMenu
  Menu-Scale exemption (`V027-05a`):** routed to the `UI-INSPECTION` pass (review Q7).
- **Promotion-picker master/detail redesign** and the **paged character sheet** remain
  with `UI-INSPECTION`; character-sheet Back keyboard access stays with `B6-INPUT`.
- **`ObjectDB instances leaked at exit` warning** (one v0.2.7 session): noted for a
  future leak audit, not a playtest item.

## Known limitations carried into this build

- **This build IS the validation vehicle.** All three repairs are visual/input and were
  verified with headless structural / event-routing tests (wall sweep + same-frame
  scroll, resize hook, write-back persistence, gray-out round-trip); `VAL-V023-DISPLAY`
  flips only after §1.3/§1.4/§1.6 pass on a real Windows screen (ideally incl. 1440p/4K
  for §1.6).
- **Headless cannot prove desktop rendering.** The anchor geometry and resize hooks are
  test-proven, but the live confirm (real window manager, real drag-resize, real
  fullscreen switches) is exactly what this rerun is for.

## Verification

- Full source suite: PASS (50 suites green; pre-commit hook gates it).
- check_docs: PASS (21/21).
- Release-metadata test (`test_release_metadata.gd`): PASS — preset name/path/product
  version, Main Menu label, checklist presence, and setup guide all agree at `v0.2.8`.
- Export: PASS — Windows debug `.exe` built headless; `res://build_info.json` confirmed
  packed (version `0.2.8`, commit `ab81a21`); SHA-256 + size recorded above.
- All visual checks live in `playtest_checklist_v0.2.8.md` and need a human pass on real
  Windows (Part I closes the v0.2.3→v0.2.8 display gate).
