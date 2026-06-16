# Playtester Build Manifest - v0.1.7.0

## Artifact

- Path: `builds/Project_Prometheus_v0.1.7.0_debug.exe`
- Source commit: `77d6dd8`
- Source subject: `Bump to v0.1.7.0: version strings + combined playtest handbook`
- Exported: 2026-06-16 20:29 UTC
- Godot: `4.6.stable.official.89cea1439`
- Size: `101,241,976` bytes
- SHA-256:
  `f8e5015cd0bbaae96071c936cc71196676ba7c65b14fc34e4895fd1fd57200fb`

The artifact is intentionally ignored by Git. Distribute **three things together**:
the executable, `AGENT/Docs/playtest_checklist_v0.1.7.0.md` (the combined feature
checklist), and `AGENT/Docs/playtest_checklist_v0.1.5.0.md` (the full handbook the
combined checklist builds on — setup, controls, and unchanged map checks).

## What's in this build (everything since v0.1.5.0)

Carried forward from the v0.1.6.0 build:

- #8.6 — reclass option lines autowrap (no horizontal scrollbar).
- #8.3 — defender Battle Speed shown on no-counter previews.
- Character-sheet stat breakdown: per-stat personal/class/cap (+ `NO_CAP_DEFINED`),
  every active bonus with source, green for boosts / red for net debuffs.
- #8.5 closure — the Pair Up bonus appears on the `I` character sheet, not just the HUD.

New since v0.1.6.0:

- **Display & Accessibility controls:** map zoom (0.25×–4×, keyboard/wheel/slider,
  cursor-anchored, persisted), resolution + window mode with a 15-second
  confirm-or-revert dialog, global UI scale (0.75×–2×), and a per-panel HUD layout
  editor (move/scale the five persistent readouts).
- **Effective compact stats** on the `I` sheet (Pair Up + combat-only sources visible
  without More Info).
- **On-map `PU` badge** for paired leads, refreshed from the registry.
- **`View Support` / `View Lead`** paired-partner navigation on the character sheet.
- **New Game** map dropdown keeps last-launched semantics; rule toggles persist on change.
- **F9 all-faction hotseat debug override** (debug builds only) with clean AI↔hotseat
  handoff.

## Verification

- Full source suite: PASS (green at the source commit; the pre-commit hook gates it).
- Export: PASS using the `Project Prometheus v0.1.7.0` Windows Desktop preset
  (x86_64, embedded PCK).
- Embedded metadata strings: PASS — `Project Prometheus`, `0.1.7.0`, and `v0.1.7.0`
  present in the artifact.
- Source-content scan: PASS — no test/AGENT source **content** is packed. Unique
  test-only code strings (e.g. `=== StatContributions Test ===`,
  `=== Combat Resolver Test ===`, `=== Release Metadata Test ===`) return zero matches,
  confirming the `exclude_filter` (`AGENT/**`, `scripts/tests/**`, `scripts/tools/**`)
  was applied.
  - **Note (precise):** the embedded UID / global-script-class caches
    (`.godot/uid_cache.bin`, `.godot/global_script_class_cache.cfg`) retain **path-only**
    references to excluded test scripts. These are cache metadata strings, not packed
    files or code, and are inert at runtime. Harmless for a debug playtest build; worth
    tidying pre-1.0 by exporting from a clean `.godot` cache.
- Embedded-pack startup: PASS — booted the executable's embedded pack with the Linux
  Godot 4.6 runtime (`--main-pack … --quit-after 5`); no engine or script errors.

Wine is not installed in the development container, so the Windows wrapper itself was
not launched here. The first-launch and all visual/input checks (the version label, the
Display & Accessibility features, the on-map `PU` badge, the character-sheet colouring,
and the F9 live handoff) remain in `playtest_checklist_v0.1.7.0.md` and need a human
pass on real Windows.
