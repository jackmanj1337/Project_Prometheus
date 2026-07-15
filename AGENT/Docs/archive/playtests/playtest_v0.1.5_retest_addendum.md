> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# Playtest v0.1.5 — Re-test Addendum & Changelog

**Status:** Superseded — folded into the full `AGENT/Docs/playtest_checklist_v0.1.5.0.md`
handbook (which now carries the "What changed since v0.1.4" re-verify summary, the
updated 8.3/8.5/8.6 checks, and the §12 features/roadmap summary). Retained for
provenance; use the v0.1.5.0 handbook for the live pass.
**Last verified:** 2026-06-14

This is **not** a full handbook. It is the focused re-test list for the build cut
after the 2026-06-14 fix pass. Use it alongside
`AGENT/Docs/playtest_checklist_v0.1.4_returned_2026-06-14.md` (the completed v0.1.4
pass): every item below is something that **changed** since v0.1.4 and should be
re-checked, plus two **new** checks. Items the v0.1.4 tester already passed and that
did not change do not need re-running.

## Build (fill in when the v0.1.5 build is exported)

- Executable: `Project_Prometheus_v0.1.5_debug.exe` _(TBD)_
- Source commit: _(TBD — `913d39e` or later)_
- Expected size / SHA-256: _(TBD — record from the export, see
  `AGENT/Docs/playtest_build_v0.1.4.md` for the manifest format)_

The fixes are verified by the automated suite and by headless geometry/logic checks.
The dev container cannot render a window, so the **visual** items below (promotion
modal, Swap, combat-preview placement, the new readouts) still need a human eyeball
pass on the real build — that is the point of this re-test.

## Changelog since v0.1.4

Fixes (each with a regression test):

- **#1 — `iron_axe` data error** (`c69347b`). The 11,829× `unknown weapon id
  'iron_axe'` log spam is gone; the four Fighter units now wield a real Iron Axe.
- **#2 — Pair Up `Swap`** (`4924dde`). Swap now actually trades lead/support roles
  and positions, not just spends the action.
- **#3 / 8.5 — Pair Up bonuses** (`b53a385`). The support's bonus now reaches the
  forecast and live combat (it previously wiped all but the last stat).
- **#4 — Allied-Rout map end + AI** (`8c2ff81`). A Rout no longer resolves while a
  hidden paired support is alive, and enemies no longer beeline to the `(1,1)` corner.
- **#5 — Promotion modal** (`e7afb51`). The class-choice modal is centered and its
  long stat rows wrap instead of running off the right edge.
- **#1.2 — New Game settings** (`2080b29`). Pair Up / Auto Promote / Leveling /
  Permadeath now persist when changed and the panel is closed without Start.
- **#2.4 — Combat preview placement** (`4c15aa0`). The preview is nudged clear of the
  objective / unit-info / terrain HUD panels.
- **#8.3 — Battle Speed** (`517b98a`). The combat preview's **Damage** More Info now
  shows each side's Battle Speed, the +5 follow-up threshold, and who doubles.
- **#8.5 UX — Pair Up indicator** (`913d39e`). A paired lead's unit-info panel shows a
  `Paired  +N Str +N Def …` line.

Decisions / polish (no behavior to re-test):

- **#8.6 — Soldier grants no skill** (`f51e8db`): intentional (placeholder Soldier
  authors no `skill_unlocks`). Not a bug; do **not** re-flag it.
- **Log noise** (`a4f44c4`): the M9 skill-stub `push_warning`s now fire once per skill
  instead of every combat, so `godot.log` is much quieter. Still review the log for
  `ERROR` / `SCRIPT ERROR` per handbook §9.

## Re-verify (previously failed/flagged — should now pass)

| Handbook § | What changed | Expected on re-test |
|---|---|---|
| 2.7 | Pair Up Swap | Choosing `Swap` trades lead/support: the new lead holds the on-map tile and is visible, the old lead goes off-map; both become DONE. |
| 2.8 | Allied Rout | With only a paired lead left, the map resolves correctly (no stall); enemies path to the lead, not to the top-left corner. |
| 8.5 | Pair Up bonuses | The paired forecast improves by the authored support contribution; live damage matches the preview. The lead's unit-info shows a `Paired …` line (see new check below). |
| 8.7 / 8.11 | Promotion modal | The Hero/Sentinel/Bow Knight modal is centered and fully on-screen at the test resolution (and under Auto Promote). |
| 1.2 | New Game memory | Change `Pair Up` / `Auto Promote`, close the panel **without** Start, reopen — the changes are remembered. |
| 9.1 | Error log | No `unknown weapon id 'iron_axe'` lines. |

## New checks to add to the handbook

- **Battle Speed in the preview (8.3).** Open a combat preview, cycle More Info to the
  **Damage** field. Expect a line showing both sides' Battle Speed, the `+5` follow-up
  threshold, and whether anyone follows up. Verify it matches the ×1 / ×2 attack count.
- **Pair Up bonus indicator (8.5).** Hover/inspect a paired **lead**. The unit-info
  panel shows a `Paired  +N Str +N Def …` line matching the authored support bonus.
  Hovering the (hidden) support is not expected to show it.

## Unchanged / still deferred

The §10 "Known deferred issues" in the v0.1.4 handbook are unchanged (camera overscan,
mouse-follow catch-up, Map Menu backdrop dismiss, per-enemy threat inspection). Do not
report them as regressions.
