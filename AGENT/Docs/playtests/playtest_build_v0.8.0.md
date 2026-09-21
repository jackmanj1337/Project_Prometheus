---
Role: dated
Type: playtest
Status: Ready - feature round
Last verified: 2026-09-21
---

# v0.8.0 Tester Candidate

The first feature round since v0.7.7. The engine no longer holds a weapon triangle: the
hardcoded table, the `WEAPON_TRIANGLE`/effectiveness switches and the fixed forecast
sentence are all deleted, and a campaign now authors its combat relationships as data
that the attack forecast reads back by name, one row per relationship that fired.

- Source branch: `agent/from-integration/v080-tester-bundle`
- Source commit: recorded in `BUILD_INFO.json` and read back from the baked BUILD STAMP.
- Baked product version / preset: `0.8.0` / `Project Prometheus v0.8.0`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: `bash run_tests.sh` green, including the acceptance pack suite (20/20)
  and the headless chapter-6 playthrough (51/51).

## What this candidate carries

- The authored trait-interaction system, slices 1-7 (`AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10`).
- The shipping Proving Grounds campaign's own triangle re-authored as data: twenty
  rules at ±10 Hit / ±2 Dmg, plus effectiveness at ×3 and `giantkiller` at ×4. The
  observable numbers are unchanged from v0.7.19 by design.
- The player-facing readout (`[ITR-6]`): named rows on the attack forecast, with More
  Info text generated from the resolution rather than from a fixed sentence.
- The suspend/resume rollback fix, the New Game build-fingerprint preference fix, the
  editor all-or-nothing save, and saved condition-registry validation.

## What the round is for

Sections 2, 3 and 7 of `playtest_checklist_v0.8.0.md` are the reason it exists. Section
7 asks for judgement about legibility, not tuning: balance, difficulty, damage curves
and pacing remain permanently out of scope (owner ruling 2026-09-05).

## Internal content

The bundle carries `proving-grounds-internal-fe.zip`, which is **internal-only** and
must never appear in a public build or video. It is the acceptance content that proves
the system can express a relationship the engine has never heard of — a weapon at two
hierarchy nodes at once, a non-weapon trait, formula-scaled magnitudes, authored
stacking and one profile suppressing another. The bundle README repeats the constraint
and the checklist asks the tester to delete their copy at closeout.
