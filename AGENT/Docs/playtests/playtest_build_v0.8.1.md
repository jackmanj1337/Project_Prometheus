---
Role: dated
Type: playtest
Status: Ready - feature round
Last verified: 2026-09-23
---

# v0.8.1 Tester Candidate

v0.8.0 with its round made testable. The authored combat-relationship system is
unchanged; what changed is that the content can reach it, the fixtures the checklist
names are in the box, and the campaign editor can be opened.

- Source branch: `agent/from-integration/v081-tester-bundle`
- Source commit: recorded in `BUILD_INFO.json` and read back from the baked BUILD STAMP.
- Baked product version / preset: `0.8.1` / `Project Prometheus v0.8.1`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: `bash run_tests.sh` green.

## What this candidate carries

Everything merged into `agent/integration` between `c712b3c7` and the cut:

- **Content reachability** (`EFFECTIVENESS-UNREACHABLE-2026-09-21`,
  `CONTENT-CANNOT-FIRE-MAGIC-OR-STACK-ROWS-2026-09-22`). Hammer and Horseslayer join the
  weapon library; Chapter 1's E2 becomes a Mage with Thunder and E3 a Cavalier; Chapter 3
  gains a Chapel Bishop with a light tome and a Bridge Fighter with the Hammer. That last
  matchup is the **first shipping fight to put two interaction rows in one forecast
  column**, and the magic triangle fires in shipping content for the first time.
- **The stat breakdown reads live combat conditions** and Unit Details names a condition
  and its remaining phases (`STAT-BREAKDOWN-OMITS-COMBAT-CONDITIONS-2026-09-22`).
- **Font glyph coverage and pack-declared UI fonts**
  (`UI-FONT-MISSING-EM-DASH-GLYPH-2026-09-22`, `PACK-DECLARED-UI-FONT-2026-09-22`). The
  shipped face covered none of the 17 non-ASCII codepoints the UI uses — including the
  ▲▼■ glyphs that are the default presentation of every authored relationship row. The
  web export has no system font to fall back on, which is why the tester's build showed
  boxes where a developer's desktop did not.
- **Confirmation dialogs name their Enter key** and focus the affirmative unless the
  action is destructive (`SUSPEND-CONFIRM-DEFAULTS-TO-CANCEL-2026-09-22`); the attack
  forecast hint now says `Enter attacks.`
- **Authoring rule ids are out of the player build**
  (`MORE-INFO-LEAKS-AUTHORING-RULE-IDS-2026-09-22`).
- **The campaign editor can be opened** (`EDITOR-MINSIZE-GATE-MEASURES-VIEWPORT-2026-09-22`)
  and **has a background** (`EDITOR-SCREEN-HAS-NO-BACKGROUND-2026-09-22`). The gate was
  measuring the fixed 1280×720 design canvas, so it was unreachable at every window size.
- **Eleven suites print a pass count** and the classifier requires one
  (`SUITES-REPORT-NO-PASS-COUNT-2026-09-22`) — not tester-visible, but it is why a green
  run means more this round than last.

## The bundle carries the fixtures its checklist names

`BUNDLE-MISSES-CHECKLIST-NAMED-FIXTURES-2026-09-22`. v0.8.0's Section 5 asked the tester
to restore `campaign_backup_v2.zip`, which was not in the bundle, and to disambiguate two
pack builds that could never collide. `build_tester_bundle.py` now parses the staged
checklist for filenames and refuses to assemble a bundle that does not carry one. This
round ships `tester-fixtures-v0.8.1.zip`, `campaign_backup_v2.zip`, both migration packs
and a genuine fingerprint-collision pair.

## The tester's content comes from the pack repo, not from `data/`

`free-roam.zip` is exported from `Project_Prometheus_Campaign_Pack_0`
`packs/proving_grounds` — see `free-roam.provenance.json` beside it — so engine-side
content changes are invisible to a tester until that tree is regenerated. It was, for
this cut, through the tracked `extract_proving_grounds_pack.gd` → `retune_public_pack.py`
path and applied as a delta. **The public pack's numbers are retuned away from the
engine's**, so a figure read off `data/` will not match what the tester sees; the
relationships and their terms are what must match.

## What the round is for

Sections 2, 3 and 7 of `playtest_checklist_v0.8.1.md`. Within Section 2, the two-row
forecast column and the magic triangle are the two checks no human has ever run. Section
7 asks for judgement about legibility, not tuning: balance, difficulty, damage curves and
pacing remain permanently out of scope (owner ruling 2026-09-05).

## Internal content

The bundle carries `proving-grounds-internal-fe.zip`, which is **internal-only** and
must never appear in a public build or video. It is the acceptance content that proves
the system can express a relationship the engine has never heard of. The bundle README
repeats the constraint and the checklist asks the tester to delete their copy at closeout.
