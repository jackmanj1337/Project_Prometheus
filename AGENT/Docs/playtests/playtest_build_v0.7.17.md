---
Role: dated
Type: playtest
Status: Candidate - exported and bundled; awaiting native return
Last verified: 2026-09-06
---

# v0.7.17 Diagnostics-First Tester Candidate

This is the first round whose executable records the state needed to interpret a
playtest return. It carries the v0.7.16 UI repairs, the diagnostics channel and session
header, save/pack lifecycle records, viewport and layout audits, battle/campaign
records, and a one-action return bundle.

- Source branch: `agent/playtest-release-v0.7.17`
- Source commit, product version, Godot version and artifact hashes: recorded in the
  bundle's `BUILD_INFO.json` and verified against the baked BUILD STAMP.
- Use `PLAYTEST_CHECKLIST.md` from the tester bundle.

## What the tester should judge

The checklist keeps only the native questions: real display/GPU/window behavior,
responsive layout, focus and input, visual clarity, save/Prep return behavior, and the
playability of the Proving Grounds campaign. It may ask for a full playthrough, but an
honest stop mid-chapter is valid.

Build diagnostics answer identity, settings, content, save/pack refusal, viewport,
layout, battle, campaign and completion questions. The round does not ask the tester
to transcribe log strings, count error lines, or assess balance, difficulty, damage
curves or pacing.

## Required bundle contents

The bundle includes the Windows release and debug executables, this build note, the
checklist, the regenerated Proving Grounds archive, the migration fixtures, and the
pack-gate receipt. The diagnostics export is produced by the tester during the run and
is returned separately.

## Release gates

The source branch must be the v0.7.17 release branch. The exact-HEAD full suite must be
green before export. The exported executable's BUILD STAMP must match the source commit
and version. Every shipped campaign archive must pass the browser import/launch gate
against the same release source commit, and the assembled ZIP must verify every staged
file and its SHA-256.

The candidate is not tagged. Tagging remains an owner decision after the native return.
