---
Role: dated
Type: playtest
Status: Ready - consolidated campaign/save candidate
Last verified: 2026-09-01
---

# v0.7.15 Consolidated Campaign and Save Candidate

This candidate replaces the never-returned v0.7.14 bundle. It carries the campaign/save
scope that v0.7.12, v0.7.13 and v0.7.14 were each cut for and none of them delivered.

- Source branch: `agent/playtest-release-v0.7.15`
- Source commit, product version, Godot version, and every artifact hash: recorded in
  `BUILD_INFO.json` and read back from the baked BUILD STAMP. This document deliberately
  does not repeat them — a stale copy in prose is how a previous round shipped a
  contradicting version claim.
- Use `PLAYTEST_CHECKLIST.md` in this bundle. It is the Revision B checklist form.

## Why v0.7.14 was not shipped

v0.7.14 was cut and never handed over. Three problems were found in it afterwards:

1. It re-shipped the **stale migration v1/v2 fixtures** byte-identical to the rejected
   v0.7.13 bundle. The v2 archive's incomplete identity declaration is exactly what cost
   v0.7.13 its migration section. The regeneration landed about fifteen hours after the
   v0.7.14 cut.
2. Its checklist was rebuilt from the older compressed draft and **dropped Section 0** —
   the user-data path, how to reach a ~360x640 window, and keeping tester exports out of
   the game folder. Without those, two sections are not performable.
3. It silently **lost the Compact Settings containment fix** that the v0.7.13 return had
   approved: that work only ever existed on the release line and on its own feature
   branch, and the v0.7.14 candidate was cut from `agent/integration`, which never
   received it.

## What this candidate carries

- The campaign traversal schema repair, so the bundled free-roam Proving Grounds pack
  imports instead of failing on `unknown_field ... traversal_mode`.
- Migration v1/v2 fixtures **regenerated from tracked sources** with identity fields
  derived from the staged catalogues.
- Approved-but-unlanded UI work merged forward from the release line: compact Settings
  containment, and slider trough/fill/endcap rendering.
- Keyboard and controller operation of OptionButton dropdowns, which previously opened a
  popup that arrow keys could not move. Never confirmed on native Windows or a physical
  controller — Section 4 of the checklist is new for this.
- Empty-profile Load Game and save-import reachability.

## Gates run before assembly

- **Full engine suite** at the exact exported commit.
- **Bundled-pack browser gate.** Every campaign that the release New Game selector offers
  for every bundled importable pack was imported from a clean browser profile, launched,
  driven through Prep, and asserted to reach a live GameMap with matching package,
  campaign and node identity, with zero import diagnostics and zero page or request
  errors. The receipt ships in the bundle as `bundle-pack-gate-receipt.json` and the
  bundler refuses to assemble without it.

Native Windows evidence remains authoritative for process-level persistence, physical
controller focus and input, and the campaign-map, migration, recovery, backup and restore
checks that no browser run can stand in for.
