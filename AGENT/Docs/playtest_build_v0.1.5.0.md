# Playtester Build Manifest - v0.1.5.0

## Artifact

- Path: `builds/Project_Prometheus_v0.1.5.0_debug.exe`
- Source commit: `5ccb508`
- Source subject: `Bump to v0.1.5.0: version strings + v0.1.5.0 playtester handbook`
- Exported: 2026-06-14 06:22 UTC
- Godot: `4.6.stable.official.89cea1439`
- Size: `101,209,032` bytes
- SHA-256:
  `d91ca65f755bdaeb7ca758fd882097a58a4e1dccaada637a74db15f811a5c5c5`

The artifact is intentionally ignored by Git. Distribute the executable and
`AGENT/Docs/playtest_checklist_v0.1.5.0.md` together.

## Verification

- Full source suite: PASS (green at the source commit; the pre-commit hook gates it).
- Export: PASS using the `Project Prometheus v0.1.5.0` Windows Desktop preset
  (x86_64, embedded PCK).
- Embedded metadata strings: PASS — `Project Prometheus`, `0.1.5.0`, and `v0.1.5.0`
  present.
- Source-content scan: PASS — no test/AGENT source **content** is packed. Unique
  test-only code strings (e.g. `=== Combat Resolver Test ===`, the v0.1.4 fix
  assertions) return zero matches, confirming the `exclude_filter`
  (`AGENT/**`, `scripts/tests/**`, `scripts/tools/**`) was applied.
  - **Note (precise):** the embedded UID / global-script-class caches
    (`.godot/uid_cache.bin`, `.godot/global_script_class_cache.cfg`) retain
    **path-only** references to ~39 excluded test scripts. These are cache
    metadata strings, not packed files or code, and are inert at runtime (the game
    never loads test classes). Harmless for a debug playtest build; worth tidying
    pre-1.0 by exporting from a clean `.godot` cache.
- Embedded-pack startup: PASS — booted the executable's embedded pack with the
  Linux Godot 4.6 runtime (`--main-pack … --quit-after 5`); no engine or script
  errors.

Wine is not installed in the development container, so the Windows wrapper itself
was not launched here. The first-launch and visual checks (version label, modal
placement, the new Battle Speed / Pair Up readouts) remain in the playtester
checklist and need a human pass on real Windows.
