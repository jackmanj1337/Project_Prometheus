# Playtester Build Manifest - v0.1.6.0

## Artifact

- Path: `builds/Project_Prometheus_v0.1.6.0_debug.exe`
- Source commit: `a947faf`
- Source subject: `Bump to v0.1.6.0: version strings + promote v0.1.6.0 checklist`
- Exported: 2026-06-14 21:34 UTC
- Godot: `4.6.stable.official.89cea1439`
- Size: `101,214,696` bytes
- SHA-256:
  `706faf26a9b49fbffde1d295cc3dd1d2239e8bcdae304c2cab66186ea7f80705`

The artifact is intentionally ignored by Git. Distribute the executable and
`AGENT/Docs/playtest_checklist_v0.1.6.0.md` together.

## What's in this build (since v0.1.5.0)

- #8.6 — reclass option lines autowrap (no horizontal scrollbar).
- #8.3 — defender Battle Speed shown on no-counter previews.
- Character-sheet stat breakdown: per-stat personal/class/cap (+ `NO_CAP_DEFINED`),
  every active bonus with source, green for boosts / red for net debuffs.
- #8.5 closure — the Pair Up bonus now appears on the `I` character sheet, not just
  the HUD panel.

## Verification

- Full source suite: PASS (green at the source commit; the pre-commit hook gates it).
- Export: PASS using the `Project Prometheus v0.1.6.0` Windows Desktop preset
  (x86_64, embedded PCK).
- Embedded metadata strings: PASS — `Project Prometheus`, `0.1.6.0`, and `v0.1.6.0`
  present.
- Source-content scan: PASS — no test/AGENT source **content** is packed. Unique
  test-only code strings (e.g. `=== StatContributions Test ===`,
  `=== Combat Resolver Test ===`) return zero matches, confirming the
  `exclude_filter` (`AGENT/**`, `scripts/tests/**`, `scripts/tools/**`) was applied.
  - **Note (precise):** the embedded UID / global-script-class caches
    (`.godot/uid_cache.bin`, `.godot/global_script_class_cache.cfg`) retain
    **path-only** references to excluded test scripts. These are cache metadata
    strings, not packed files or code, and are inert at runtime (the game never
    loads test classes). Harmless for a debug playtest build; worth tidying pre-1.0
    by exporting from a clean `.godot` cache.
- Embedded-pack startup: PASS — booted the executable's embedded pack with the
  Linux Godot 4.6 runtime (`--main-pack … --quit-after 5`); no engine or script
  errors.

Wine is not installed in the development container, so the Windows wrapper itself
was not launched here. The first-launch and visual checks (version label, the
reclass wrap, the no-counter Battle Speed line, and the new character-sheet
breakdown with its green/red colouring) remain in the playtester checklist and need
a human pass on real Windows.
