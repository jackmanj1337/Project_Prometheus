---
Type: plan
Status: Superseded — v0.7.3 returned and later rounds replaced this queue
Last verified: 2026-08-24
Tracker: V071-RETURN-TRIAGE-2026-08-09
---

# Next-session handoff — what to do while v0.7.3 is out for playtest

> **Superseded** on 2026-08-24: this waiting-state handoff is historical. Current release
> remediation is owned by
> [`windows_pass_readiness_handoff_2026-08-20.md`](windows_pass_readiness_handoff_2026-08-20.md).

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md),
with cross-repo task state in `coordination/tasks.json` (Container repo). The
v0.7.3 candidate is exported and bundled; nothing in this handoff touches a
frozen release line.

## 1. Where things actually stand

**v0.7.3** was exported and bundled 2026-08-10 from
`agent/playtest-release-v0.7.3` at `3f72688f` (release 105,943,056 bytes; both
manifests read BUILD STAMP 0.7.3/3f72688f; all 136 suites green at the exported
commit). It is waiting on a human playtest. Nothing here should modify it.

**v0.7.1 remediation is finished, not pending.** All five implementation items
from the audit's priority list are merged to `agent/integration`: pack discovery,
campaign-resume atomicity, user-data migration atomicity, the game-owned filename
modal replacing FileDialog Escape interception, and the zero-content export gate.
What remains for v0.7.1 is **Windows acceptance only** — validating the filename
modal and the content-free build in a return. Do not treat it as open
implementation work, and do not represent the feature-branch development-evidence
artifact as release-qualified.

**The August full audit is now on this line.** It was stranded on
`agent/from-integration/full-audit-2026-08` until 2026-08-10; the rollup and the
five pillar reports are now readable from `agent/integration`. Anyone told to
"read the rollup" before that date was reading nothing.

## 2. The recommendation

Work the audit's **priority 8**, tracked as
`AUDIT-DOC-AUTHORITY-RECONCILE-2026-08-09`.

The rollup rates it *high authority risk / small effort*, which is the best ratio
on the remaining list, but the reason to do it **now specifically** is timing.
The GDD currently overstates shipped behaviour for exactly two things: campaign
resume atomicity and native FileDialog Escape. Those are the two behaviours the
v0.7.1 fixes changed and that the next Windows return exists to validate. Left
alone, the next tester or agent reads claims that contradict both the defect that
was found and the fix that replaced it — during the window when that document is
what someone will reach for.

Scope, from `AGENT/Docs/documentation_review_2026-08-09.md` and rollup §4
(CROSS-4):

- `OPEN-11` still describes UI scale as a future trigger, after scale controls
  landed. Reconcile it to its delivered state or to the remaining responsive
  scope.
- The active lifecycle document still teaches the pre-typed `AGENT/Docs/` layout.
  The rewrite should land with a narrow check against obsolete flattened paths,
  so the same drift cannot recur silently.
- Correct the resume and FileDialog clauses to match what shipped.

These are integration-only authority repairs. They do not touch the frozen
candidate, which is what makes them the right shape of work for a playtest wait.

## 3. If that is already done, or you want something else

In the audit's own order:

- **Priority 7 — `AUDIT-RETIRE-INVENTORY-CONVERTER-2026-08-09`.** Retire the
  stale absolute-path inventory converter, or replace it with an explicit-root,
  dry-run-first, tested CLI. Small and self-contained.
- **Priority 9 — `AUDIT-CONTROL-PLANE-LIVENESS-2026-08-09`.** Claim liveness,
  session-note/index bijection, and DoD#1 changed-path reporting. Note that
  **audit-cadence reporting already landed** — the pre-push hook now emits
  `audit-cadence: N day(s) and N commit(s) since full_review_rollup_2026-08-09.md`.
  It only started producing a real number once the rollup reached this line, so
  re-measure before implementing. The row says to repair four measured missing
  index rows during implementation; that count predates the 2026-08-10 audit
  merge and should be re-counted rather than trusted.
- **Priority 6 is done.** `AUDIT-TOOLING-TEST-DISCOVERY-2026-08-09` was built at
  `4e28a321` and merged at `acae6d0c`; integration tip `e6378069` passed 23 Python
  infrastructure tests, 28 browser assertions and all 136 Godot suites. Its row is
  still `in_review` and wants a status decision, not more work.

## 4. Work deliberately not recommended yet

- **The web visual-verification programme** (Container repo:
  `TOOLING-NAV-CALIBRATE`, `BRIDGE-SNAPSHOT-STALENESS`, `TOOLING-IMAGING-DEPS`,
  `EXP-CV-SCREENSHOT-CHECKS`). Real, ready, and ordered 145–148 — which is to say
  behind the audit follow-ups. `TOOLING-NAV-CALIBRATE` is the honest pick if
  tooling is wanted anyway: cheap, independent, and it retires hand-maintained
  coordinates.
- **Any UI theming rollout.** `SESSION-UI-THEMING-ALIGNMENT-2026-08-10` must run
  first. The theme seam is half-built — `assets/themes/manasoul_ui.tres` covers
  four control types on 7 of 21 UI scenes — and rolling it across the other 14
  would be discarded by `EPIC-SHARED-RECORD-UI-V1` and the small-screen redesign,
  which restructure the same scenes.

## 5. Owner actions this cannot proceed without

- **The v0.7.3 playtest itself.** Everything on the release line waits on it.
- **`Project_Prometheus_Container` promotion.** `agent/staging-area` is 338
  commits ahead of `main`, with no promotion since PR #31 merged on 2026-08-04.
- **D5 follow-through.** Pillow and numpy are approved; the install is scheduled
  as `TOOLING-IMAGING-DEPS-2026-08-10` and needs an image rebuild, which is
  disruptive enough to want deliberate timing.
