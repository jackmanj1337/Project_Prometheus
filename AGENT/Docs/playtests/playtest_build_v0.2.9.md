# Playtester Build Manifest - v0.2.9

> **Status:** exported 2026-07-07. Windows debug `.exe` built with Godot `4.6.stable`;
> the release metadata (`export_presets.cfg`, Main Menu `VersionLabel`,
> `environment_setup.md`) is at `v0.2.9`.

## Artifact

- Path: `builds/Project_Prometheus_v0.2.9_debug.exe`
- Source commit: `3dddefc`
- Baked build stamp (`build_info.json`): version `0.2.9`, commit `3dddefc`,
  built_at `2026-07-07T06:35:12Z`
- Exported: `2026-07-07`
- Godot: `4.6.stable.official.89cea1439`
- Size: `101375272` bytes
- SHA-256: `fb064f2a24bab20d8854c5ecbeda04f078463e170e0be9f22ec3c8e5816cf3f8`

The artifact is intentionally ignored by Git. v0.2.9 ships as **two files**: the
executable and the single self-contained handbook
`AGENT/Docs/playtests/playtest_checklist_v0.2.9.md`. No `._sc_` marker; the log lands in
the OS user-data dir (`%APPDATA%`) and the startup BUILD STAMP's `log=` line reports the
exact path — that flow worked on the v0.2.7 and v0.2.8 returns.

## Why v0.2.9

v0.2.9 is the **third display-gate rerun** (`VAL-V023-DISPLAY`). The v0.2.8 return
(2026-07-07) **passed §1.3 and §1.4 live** (action-menu anchoring and combat-forecast
placement), and confirmed Borderless/Fullscreen Resolution gray-out — so the gate
narrowed to **§1.6 only**, with two new reports (triage:
`playtest_v0.2.8_results_triage_plan_2026-07-07.md`). The owner walked review Q1-Q3 the
same day and the section-1.6 fix pass landed on this branch (`65dde85`). This is a **pure
rerun build** — it carries the V028 fixes and no feature work; Part I of the handbook is
**§1.6 only**. `VAL-V023-DISPLAY` flips only when §1.6 passes on a real Windows screen.

## What changed since v0.2.8

Each maps to a Part I §1.6 check in the v0.2.9 handbook.

- **Custom-size readout semantics (`V028-02`, review Q1, §1.6a):** the saved `resolution`
  string carries two meanings the readout used to conflate — a preset **request** (the
  usable-rect clamp may shrink it) vs. a custom **observed client size** written back by an
  OS resize (already applied). `SettingsManager.windowed_size_status()` now tags which is
  which; `SettingsScreen._refresh_applied_size` renders a custom value as **`client W×H`**
  and never re-runs it through the 16:9 request clamp — killing the
  `Custom (3840x2071) → applied 3563x2004` output the tester saw.
- **Windows maximize = window state, not a resolution (`V028-03`, review Q2, §1.6b):**
  `SettingsManager.resize_write_back_action()` (a pure, headless-testable policy over the
  current + previously observed `DisplayServer.window_get_mode`) **ignores** the maximized
  state (never persisted) and **restores** the saved windowed size on the
  maximize→windowed transition; only a genuine windowed edge drag writes back.
- **Reactive menu re-center (`V028-03` root cause, review Q2, §1.6b):** the recurring
  "menu recenters on adjusting the size instead of staying put" symptom is fixed at the
  cause. `MenuScale._recenter` was a one-shot imperative offset-bake that went stale on
  Godot's deferred layout pass (patched per-trigger four times: V025-05a / V026-01a /
  V027-04a / V028-03). Each centered panel's own `resized` signal now drives a re-entrancy-
  guarded re-center, so centering re-runs at the exact frame the panel size settles. The
  viewport `size_changed` hook is kept for the V021-08 fit-clamp + write-back only.

## Deferred / not in this build

- **Aspect-ratio / black-bars viewport expansion (`V028-04`):** routed to
  `UI-VIEWPORT-ASPECT`; a platform/UI policy decision (Steam Deck 16:10, mobile), not a
  section 1.6 defect.
- **Structural `CenterContainer` menu-centering refactor:** the clean form of the V028-03
  fix (wrap centered panels in `CenterContainer`, delete imperative `_recenter`) is folded
  into `UI-VIEWPORT-ASPECT`.
- Carried from earlier: `UI-INSPECTION` (frame-size stability, promotion-picker/character-
  sheet redesign), character-sheet Back keyboard access (`B6-INPUT`), and the `ObjectDB`
  leak audit.

## Known limitations carried into this build

- **This build IS the validation vehicle.** The §1.6 repairs are visual/input and were
  verified with headless structural / policy tests (`windowed_size_status` preset-vs-custom
  with no re-clamp; `resize_write_back_action` drag/maximize/un-maximize policy; reactive
  re-center of a panel the engine grows after apply). `VAL-V023-DISPLAY` flips only after
  §1.6 passes on a real Windows screen (ideally incl. the Windows maximize button at 2.0×
  Menu Scale, and a non-preset drag-resize).
- **Headless cannot prove desktop rendering.** The re-center reacts to a real `resized`
  signal and the maximize policy reads a real `DisplayServer` window mode — the live
  confirm (real window manager, real maximize/restore, real drag-resize) is exactly what
  this rerun is for.

## Verification

- Full source suite: PASS (62 suites green; pre-commit hook gates it).
- check_docs: PASS.
- Release-metadata test (`test_release_metadata.gd`): PASS — preset name/path/product
  version, Main Menu label, checklist presence, and setup guide all agree at `v0.2.9`.
- Export: PASS — Windows debug `.exe` built headless; `res://build_info.json` packed
  (version `0.2.9`); SHA-256 + size recorded above.
- All visual checks live in `playtest_checklist_v0.2.9.md` and need a human pass on real
  Windows (Part I §1.6 closes the v0.2.3→v0.2.9 display gate).
