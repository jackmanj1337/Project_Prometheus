---
Role: dated
Type: playtest
Status: Ready - batched native-host round
Last verified: 2026-08-20
---

# v0.7.8 Tester Candidate

This is the **batched native-host round**. Seven rows have been waiting on a real
display, a real keyboard and controller, or a screen reader, and none of them can be
answered in the container. It is deliberately Windows-only: the open iOS, mobile-web and
touch rows need a phone or a touch device and are excluded rather than shipped as
unanswerable checklist items.

- Source branch: `agent/playtest-release-v0.7.8`
- Source commit: recorded in `BUILD_INFO.json` and read back from the baked BUILD STAMP.
- Baked product version / preset: `0.7.8` / `Project Prometheus v0.7.8`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: `bash run_tests.sh` green on the exported HEAD (148 suites).

## What is new since v0.7.7

Three `in_review` branches were merged into `agent/integration` for this build, because a
visual-pass or announcement row can only be answered if its work is actually in the exe:

- **`UNMET-REASON-TEXT-TABLE-2026-08-20`** — `TextDB` is now an autoload over
  `engine_data/text/en/core.json`, and unmet reasons render as sentences instead of as
  their own internal ids. Without this, `[ANN-5]` would have tested the announcement path
  by listening to a screen reader read `req.has_item` aloud.
- **`V080-RESPONSIVE-MAIN-MENU-2026-08-08`** — the Main Menu responds to size classes and
  density tokens.
- **`UI-PHASE0-UNBLOCKED-ITEMS-2026-08-16`** — context-scoped `ResponsiveLayout`, the
  four-column token file, the role list, and slider/scrollbar paint.

One defect was found and fixed while writing the checklist: **Continue and Load Game were
gated with no reason at all.** Only New Game carried a tooltip, so a keyboard or
screen-reader user reached a dimmed button that explained nothing — the outcome
`[EPUX-07]`/`[RPD-15]` rejects by name. It would also have degraded this round's most
valuable observation, since `[ANN-5]` would have found silence on two of the three gated
entries it was booked to test. Both now read their reason from the shared table.

## What this round answers

| Checklist section | Row |
|---|---|
| 1. Screen reader | `SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19` (`[ANN-5]`) |
| 2. Keyboard and controller | `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17` (sole residue) |
| 3. Gate reasons | `UNMET-REASON-TEXT-TABLE-2026-08-20` |
| 4. Main Menu / UI sizing | `V080-RESPONSIVE-MAIN-MENU-2026-08-08`, `UI-PHASE0-UNBLOCKED-ITEMS-2026-08-16`, part of `SMALL-SCREEN-UI-REDESIGN-2026-08-05` |
| 5. Terrain | `IMPL-TERRAIN-VARIANTS-AND-PACK-TERRAIN-2026-08-01` |
| Carried over | `V076-RETURN-RESIDUE-2026-08-16` (two questions for the owner, not build items) |

Use `playtest_checklist_v0.7.8.md`. It asks for **observed text rather than a tick**
wherever a fallback string would look plausible — `req.has_item` and
`#missing:req.has_item` are both non-empty and both look like real UI text, so "yes,
something was there" cannot distinguish a working table from a broken one.
