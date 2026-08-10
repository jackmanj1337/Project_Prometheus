# Session Notes — 2026-08-10-04-22-29Z-v0-7-3-first-run-library-tester-bundle (v0.7.3 first-run library tester bundle)

## What was done

- Cut `agent/playtest-release-v0.7.3` from the frozen v0.7.2 tip `cb5906e8`, so the
  candidate carries the whole v0.7.2 remediation programme plus the first-run Campaign
  Library repair (`09365ac9`) that landed after the v0.7.2 bundle was assembled.
- Advanced the governed release identity from `0.7.2` to `0.7.3` across the export
  preset name, export path, `application/product_version`, the Main Menu version label,
  and the environment guide.
- Added the build record `playtest_build_v0.7.3.md` required by the release-source
  guard, a `playtest_checklist_v0.7.3.md` pointer, and a focused
  `playtest_checklist_v0.7.3_windows.md` that leads with the first-run Campaign Library
  route before repeating the v0.7.2 content-free, filename-modal, and migration
  sections.
- Produced release and debug Windows exports through the release-qualified exporter,
  audited the packed content, and assembled the private tester bundle.
- Marked the undelivered v0.7.2 build record and checklists superseded so only one
  candidate reads as awaiting a return.

## Factual Git state

- Branch: `agent/playtest-release-v0.7.3`
- Exported commit: `3f72688f7d48e5ceb4ea93bcda4aa1615ef31749`
- Task merge base: `cb5906e8c19f0dc45e5a99d25e9284cd94bb5616`

## Commits

- `3f72688f` Prepare v0.7.3 first-run library recut
- plus this note and the exported-evidence update to the build record.

## Checks

- `full`: all 136 suites green at `3f72688f`; the full-check receipt records tree
  `851a93898b1acafdf1056edca8a0bcf3a9354a33`, which both artifact manifests name as
  their `source_tree`.
- Release export: 105,943,056 bytes, SHA-256
  `4977a00a5e6653bc6c9a6119f469489b475f925d5fe770a1622e0eaeb5d856de`.
- Debug export: 102,071,312 bytes, SHA-256
  `5058cfe54985405c732f8f79e037de22cff77ac82898bfe28aa1c1b5b08797db`.
- Both artifact manifests read back BUILD STAMP `0.7.3/3f72688f`.
- PCK audit: 658 entries, zero top-level `data/**`; the only `/data/` substring matches
  are `scripts/data/EntitySchemaRegistry.gdc` and its `.gd.remap`, both engine code.
- Bundle integrity: 10/10 staged files present, archive test passed; bundle SHA-256
  `940f4829edf1d58ac30868795f07eca33f3bb58fee1e3f062886c47eda7729f7`.
- Replacement pack: reused unchanged from v0.7.2 — 150 files, single
  `prometheus-v071-playwright-test/` root, SHA-256
  `36be0615b5799043d341487e40e898636d418a45c041c479ffdc27b3de16a423`.

## Decisions and context

- v0.7.2 was never delivered for a native round. On a fresh install it reached the
  Campaign Library only through the disabled New Game route, so a tester with no
  installed content had no way to import the supplied pack — the first checklist section
  would have blocked the whole round. Shipping v0.7.2 as-is would have burned a Windows
  round on a known dead end, so v0.7.3 replaces it rather than amending it.
- The version bump to `0.7.3` (rather than re-cutting `0.7.2` from a new tip, which the
  previous handoff proposed) is the owner's call, recorded here because the BUILD STAMP
  and the tag policy both key off it: two different executables must never share one
  version string.
- `agent/playtest-release-v0.7.2` is untouched and stays frozen at `cb5906e8`; its
  bundle remains in `builds/tester/` for reproducibility.
- The replacement pack is reused because its archive structure and contents are still
  valid; this candidate tests engine and first-run behavior, not new pack content.
- The previous Windows exports were rotated to
  `builds/{windows,windows_debug}/previous/Project_Prometheus_pre_v073_20260810T042049Z`
  rather than overwritten. Release mode refuses `--force`, so rotating is the only way
  to re-export.

## Next session

Deliver `builds/tester/Project_Prometheus_v0.7.3_tester_bundle.zip` for the private
Windows round and keep `agent/playtest-release-v0.7.3` frozen until it returns. When the
return arrives, verify BUILD STAMP `0.7.3/3f72688f` and the SHA-256 digests before
triaging anything. Section 2 of the checklist is the new evidence this round exists to
get: the first-run Campaign Library route must be confirmed on a genuinely clean
user-data directory, with keyboard and controller, before the rest of the round counts.
Headless or container evidence must not close the game-owned filename-modal row or the
v0.7.1 remediation programme.
