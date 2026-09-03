---
Role: dated
Type: playtest
Status: In preparation - candidate branch cut, not yet exported
Last verified: 2026-09-03
---

# v0.7.16 Banner-Measurement and Visual-Pass Candidate

This candidate exists to collect the two things the container cannot produce: an
instrumented native capture of the phase-banner defect, and a first look at five fixes
that are merged but have never been seen on a real display.

- Source branch: `agent/playtest-release-v0.7.16`
- Cut from `agent/integration` at `0636e29e`.
- Source commit, product version, Godot version, and every artifact hash: recorded in
  `BUILD_INFO.json` and read back from the baked BUILD STAMP. This document deliberately
  does not repeat them — a stale copy in prose is how an earlier round shipped a
  contradicting version claim.
- Use `PLAYTEST_CHECKLIST.md` in this bundle. It is the Revision B checklist form.

## Why this round is not a normal recut

The v0.7.15 return carried nine findings. **Eight are fixed and merged. The ninth cannot
be fixed here**, and that is not a scheduling excuse: the phase banner's persistence
defect does not reproduce headless (the full 1.4 s settle case passes in a bare tree) and
a Playwright attempt could not load the returned suspend save at all. The owner ruling on
that row is to **instrument first and patch second**, so shipping a build that measures
the defect is the work, not a substitute for it.

So this bundle's primary deliverable is Section 2 of the checklist: the tester runs
`run-with-banner-trace.bat`, reproduces the stuck banner once, and returns the log. The
`BANNER_TRACE` lines carry panel visibility, panel geometry, the viewport rect, the window
size, the content-scale factor and `tree_paused` — the last of these because the leading
hypothesis is that a phase transition is being animated through a scene that is still
restoring, not that the banner's own animation is wrong.

## What this candidate carries

- **The acceptance drill (V0715-09).** The campaign opens on `map_000_drill`: one enemy,
  1 HP, no defences, reachable on turn 1. Chapter 1 is untouched and sits behind it. This
  is why the save sections are cheap to run this round.
- **Migration fixtures that actually migrate the returned saves (V0715-02).** Both saves
  the tester returned were driven through the rebuilt fixtures and preview with zero
  diagnostics.
- **Diagnostic severity and dialog wording (V0715-05).** An expected disabled-save state
  no longer reports through `push_error`, and raw `migration_*` codes no longer reach the
  Load Game dialog.
- **Five fixes awaiting their first real display:** nested modal stack (V0715-06),
  vertical Compact Settings rows (V0715-03), slider trough/fill/endcaps (V0715-04), the
  manual-save replacement picker and the Prep return origin (V0715-07/08).
- **Banner instrumentation**, inert unless `PROMETHEUS_BANNER_TRACE=1` is set. It is
  scaffolding for one measurement and is deleted when V0715-01 lands.

## What it deliberately does not ask for

The dropdown keyboard/controller work, Proving Grounds import and progression, backup and
restore, renewal ticking and suspend/reload HP all passed on v0.7.15. The checklist asks
for regression smoke on them and nothing more. Re-testing a passing surface is how a round
runs out of tester time before reaching the thing it was cut for.

## Pack provenance, changed this round

The bundled free-roam Proving Grounds archive is **rebuilt from tracked sources** by
`<container>/scripts/rebuild-pack-archive.sh`, which writes a provenance sidecar naming
the source repo, branch, commit and the git tree hash of the pack directory. Every bundle
from v0.7.12 to v0.7.15 re-copied that ZIP unchanged from an unmerged branch with no
record of where it came from. A pack archive is not bit-reproducible — ZIP embeds mtimes
— so the tree hash, not the archive SHA, is what ties a shipped pack to a commit across
rounds.

## Gates still required before assembly

Not yet run. This document is updated in place when they are.

- Full engine suite at the exact exported commit.
- `scripts/tools/prepare_build.sh` bake and BUILD STAMP verification.
- Bundled-pack browser gate (`scripts/bundle-pack-playwright-gate.mjs`) against the web
  export for this commit; `build_tester_bundle.py` refuses to assemble without its
  receipt.
