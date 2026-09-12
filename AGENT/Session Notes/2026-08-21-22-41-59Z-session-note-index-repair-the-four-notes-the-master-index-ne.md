# Session Notes — 2026-08-21-22-41-59Z-session-note-index-repair-the-four-notes-the-master-index-ne (Session-note index repair: the four notes the master index never listed)

## What was done

Repaired the session-note index bijection that the control-plane liveness audit
measured: **578 notes against 574 index links**. Four notes were reachable only by
listing the directory, so nothing that navigates by the index could see them at all:

| Note | Why losing it mattered |
|---|---|
| `2026-07-11d` | The theme rollout `2026-07-11b` deferred until the `MenuScale` fix landed — including the removal of a hardcoded `theme_override_styles/panel` on `SettingsScreen` that would have shadowed the theme regardless of MenuScale. |
| `2026-07-11e` | `V027-05a` resolved: `MenuScale.apply_to_fit_rect()`, the first primitive that GROWS a panel to a fit instead of only shrinking a requested factor, and the measurement that the fit is **not** proportional to factor (a Button's StyleBox padding is a fixed additive term, so a one-shot proportional estimate landed at (158,305) against an achievable (199,389)). |
| `2026-07-30-12-00-00Z-light-dark-tomes` | The Light/Dark tome families, Cleric resolved to staff-only, and the validation that rejects a class weapon-WEXP track with no authored weapon in the active content set. |
| `2026-07-30-12-30-00Z-fe-numeric-audit` | The FE numeric provenance audit and the owner call it left open — replace the compatibility preset with an independently budgeted base pack, or retain it under explicit provenance terms. |

Two of the four are the *only* record of a shipped primitive and a shipped
validation rule. That is the cost of an index gap: not a missing link, a missing
piece of the reasoning trail.

**Ordering is a separate matter and is deliberately untouched.** `history_audit
notes` still reports `consistent=false` now that `bijection_consistent=true`,
because **114 of the 578 rows sit out of reverse-chronological order**. That is
pre-existing, it predates this row, and it is not mechanically fixable by sorting:
the legacy `2026-07-19a..d` and `2026-07-19-b..c` filenames encode two different
same-day conventions that the audit's sort key ranks against each other, so
"correct" order for that stretch is a judgement, not a rule. Anyone wanting
`consistent=true` as a gate has to settle that first.

## Factual Git state

- Branch: `agent/integration`
- HEAD: `53301f76d054036ef8e57373dac9c2ef4836b873`
- Task merge base: `aa9eeb49c045fff5f3072da6f5ab2b1a3ad5e9b3`

## Commits

- `dfc59fb6` Index the four session notes the master index never listed
- `53301f76` Merge session-index repair

## Checks

- `full`: `bash run_tests.sh` at `53301f76d054`

## Decisions and context

- The four rows were placed by the audit's own sort key, not by eye:
  `12-30-00Z` then `12-00-00Z` between `16-12-16Z` and `08-45-41Z`; `11e` then `11d`
  between `2026-07-12` and `2026-07-11c`. Both blocks are locally correct. They still
  appear in `ordering_errors` because every position in the 58–189 window mismatches —
  that window is shifted by the pre-existing disorder, not by these insertions.
- This is the Project half of `AUDIT-CONTROL-PLANE-LIVENESS-2026-08-09`. The audit
  tooling itself lives in the container repo; only the repair lands here.

## Next session

The v0.7.8 Windows round is **still out** (`WINDOWS-PASS-READINESS-2026-08-20` is
`in_progress`) and **a returned packet preempts everything**. Nothing in this session
touched product behaviour.

Left open by the liveness programme, in the order they matter:

1. **`IMPL-ZERO-CONTENT-BASE-PACK` holds a directory-wide claim on `assets/`.** It
   blocked `UI-PHASE0-UNBLOCKED-ITEMS-2026-08-16` from reserving the theme file it had
   already edited, so that claim was dropped rather than contested. The broad claim
   will collide with every future theme or art row; narrowing it belongs to
   `IMPL-ZERO-CONTENT-BASE-PACK`.
2. **114 index rows out of order**, as above — the last thing between
   `history_audit notes` and being usable as a gate.
3. `BUMP-AGENT-CLIS-2026-08-21-2026-08-21` is `in_progress` and **cannot be finished
   from inside the container**: it needs a host-side `scripts/rebuild-image.sh
   --recreate`, which would replace the running session. Its pin also disagrees with
   what is installed (`CLAUDE_CODE_NPM_VERSION=2.1.239`, installed `2.1.238`), so the
   rebuild is what decides which one is real.
