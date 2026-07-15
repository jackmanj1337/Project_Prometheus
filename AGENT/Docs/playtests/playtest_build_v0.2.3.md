# Playtester Build Manifest - v0.2.3

> **Status:** exported 2026-06-20. Windows debug `.exe` built with Godot `4.6.stable`;
> the release metadata (`export_presets.cfg`, Main Menu `VersionLabel`,
> `environment_setup.md`) is at `v0.2.3`.

## Artifact

- Path: `builds/Project_Prometheus_v0.2.3_debug.exe`
- Source commit: `76060ca`
- Exported: `2026-06-20`
- Godot: `4.6.stable.official.89cea1439`
- Size: `101264440` bytes
- SHA-256: `b92301f62a29523dc3b5adb3eb64e40e3afe9d8bfd5a70733d49791adadae107`

The artifact is intentionally ignored by Git. v0.2.3 ships as **two files**: the
executable and the single self-contained handbook
`AGENT/Docs/playtests/playtest_checklist_v0.2.3.md`.

## Why v0.2.3 (and what happened to v0.2.2)

The last build cut for playtest was **v0.2.1**. The v0.2.2 feature round was implemented
but **never built for playtest** (the user chose to fold it into the next display build
rather than cut an interim v0.2.2 checkpoint). v0.2.3 is the "Display Scaling &
Resolution" build (a minor bump: crisp scaling + native resolutions + the renderer
switch), and it carries the unplayed v0.2.2 work with it. **So this single build contains
two unplayed rounds**, reflected in the handbook's Part I (display) + Part II (v0.2.2).

## What's in this build (since v0.2.1)

**Display & rendering (v0.2.3):**

- **D1** renderer → `gl_compatibility` (shared prerequisite with the coming web build).
- **V021-18 / D2** crisp Menu Scale — `MenuScale.apply_to` leaves `Control.scale == 1`
  and scales type (runtime-derived Theme + override walk); centered panels recentre at
  natural size, contextual menus keep their cursor anchor, scroll panels keep their frame.
- **V021-08** long-menu fit clamp (reduces the font factor, not the bitmap scale).
- **V021-19 / D4** native `2560×1440` + `3840×2160` resolutions.
- **D5 / E6** single safe-area provider seam (zero on desktop).
- **E5** explicit `window/stretch/aspect="keep"`; **E1** desktop-only display gate.
- **LevelUpScreen** converted `Panel`→`PanelContainer` for clean type scaling.

**Gameplay / UI (unplayed v0.2.2 round):**

- **V021-01** F9 hotseat mid-activation rollback (no re-move on replay; mid-move units
  roll back to start).
- **V021-02 / V021-03** HUD-layout-editor input capture + sample-text clipping; reset
  reflow hardened.
- **V021-05** terrain More Info paging (Hidden → Description → Movement).
- **V021-06** character-sheet directional selector (true vertical Up/Down).
- **V021-07** map HUD pair-up line names support only, raised so it isn't clipped.
- **V021-09** stat-modifier duration display vocabulary.
- **V021-10** class summary relocated into class More Info.
- **V021-11** movement-type system (explicit `infantry`, precedence, flying column).
- **V021-13** Map Menu backdrop-click dismiss.
- **V021-14** weapon names in the combat forecast.
- **V021-16** cancel-over-unit opens the character sheet.
- **V021-17** mouse cursor modes `follow | click | disabled`.

Plus the pre-build cleanup (`dcff28d`): movement-type resolution dedup and a `save()`
side-effect removal (no behaviour change).

## Known limitations carried into this build

- **Live crispness + resolution verification is the remaining gate.** `V021-18` and
  `V021-19` are roadmap status `[~]` (implemented, pending live verify) — this build IS
  the vehicle for that verification. They flip `[x]` only after the handbook's Part I
  passes on a real screen.
- **V021-04** (HUD panel crisp scale + terrain corner-snap) is deferred — the crisp
  rework is menus-only this build.

## Verification

- Full source suite: PASS (48 suites green; pre-commit hook gates it).
- check_docs: PASS (16/16).
- Export: PASS — Windows debug `.exe` built headless, SHA-256 recorded above.
- All visual/input checks remain in `playtest_checklist_v0.2.3.md` and need a human pass
  on real Windows (Part I is the v0.2.3 closeout gate).
