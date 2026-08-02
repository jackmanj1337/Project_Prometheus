# Session Note - 2026-08-02 v0.6.1 release tooling and review fixes

## Branch context

- Branch: `agent/from-v060-return-fixes-playtest/v061-ui-playwright-responsive`
- Base branch: `agent/from-v0.6.0-visual-pass/playtest-patches`
- Base SHA: `cbd1f83257bc68fad1ccdec0bbcb8d5faa7df295`
- Prior note: `2026-08-02-07-24-02Z-v060-return-fixes.md`
- Container tooling branch: `agent/from-playwright-harness/release-tooling`
- Coordination Work ID: `GOAL-V060-RETURN-FIXES-2026-08-02`

## What was done

A review of the previous session's work, the script fixes that review implied, and a
rebuild of the tester bundle from a correctly stamped export.

**The shipped v0.6.1 bundle was wrong.** Both executables carried
`version=0.6.0 commit=cbd1f832` in `res://build_info.json`, because
`scripts/tools/prepare_build.sh` was never run before the export. The in-game BUILD
STAMP — the value release tag policy binds a tag to, and the only authoritative
identity in a returned log — therefore disagreed with the filenames, the checklist and
the release notes. The cause was a missing `AGENT/Docs/playtests/playtest_build_v0.6.1.md`:
`check_release_source_branch.py` refuses to bake without one, so the bake was skipped
rather than fixed. That record now exists, and the exporter bakes and re-verifies the
stamp itself instead of trusting an operator to have done it.

Code fixes from the review:

- Centered modal frames no longer treat the 90% safe-viewport cap as a target. A panel
  authored without a `custom_minimum_size` was pinned to exactly the cap on both axes;
  LoadGameScreen's 480x360 dialog rendered at 1152x648 at 720p. A scene may state its
  size as a `custom_minimum_size` or as an anchor span plus offsets, and only the first
  was being read.
- `RegistryManager.commit_candidate` records why it refused, so DataManager's Tier-2
  failure path no longer reports the previous state's (empty) error list.
- `TransitionTelemetry` tracing is debug-only; release keeps the ring in memory and
  flushes it when the watchdog fires. It previously printed a JSON line per GUI focus
  change for the whole session in a shipped build.
- `HUD.set_panel_attachments` gained the null-panel and empty-layout guards its sibling
  already had; `_layout_base_positions` and `_terrain_expanded_offset` were removed as
  write-only leftovers of the attachment rewrite.
- `TextEntryService` guards its host viewport with `is_instance_valid` (a freed
  FileDialog Window passes `!= null`) and exposes `overlay()` / `owns_focus()`, so the
  input guard and the web bridge stop reaching into `_overlay`.
- Query-seeded content scale no longer persists to the settings file, where it leaked
  into later instrumented runs that omitted the parameter.

Tooling, in this repo:

- `check_gdscript_style.sh --fix` formats in place, and now covers new untracked files
  — the check-only form used `git ls-files`, so a newly added `.gd` was invisible to it
  and rejected by the hook that saw it staged.
- `run_tests.sh --rerun-failed` re-runs only the suites recorded in `.test-failures`,
  serially, so process contention can be told apart from a defect with a record.
- `check_session_commit_claims.py --fix` appends unclaimed commits to the newest note.
- Every rejection message names its remedy.

## Commits claimed

- `88714facd09cfeb53032d59c5713d4ab5a7242d6` — Stop the responsive cap becoming the modal size
- `ea2b672c13725a27df6dcf70ad023a30d4de4aeb` — Report registry failures, bound telemetry output, harden HUD edits
- `8f535ecbeb436b67601d8841ac0b0d1008084d80` — Add fix modes to the checks that reject a commit
- `d0f57262b7e3ad1d291cb8db248af8d2dea5de3a` — Add the v0.6.1 build record that unblocks the stamp bake
- `7c598e46037574cdde96aba5cfda08760717615b` — Test the release-source version behaviour, not a literal

The bundle was rebuilt from a correctly stamped export. Both executables now come
from the same commit `a3987961` and carry `version=0.6.1 commit=a3987961`; the earlier
pair came from two different commits and both said v0.6.0. The Playwright album was
regenerated against the fixed code, and diffing observed frame sizes against the
previous run is what caught a regression this session introduced: NewGameScreen
collapsing to 458x32 once its scroll frame fell back to a content minimum. 133/133
passed either way, which is precisely why the frame-size diff — not the pass count —
is the useful signal.
- `a39879613a89259ec4bbb284f0cdd58db468799e` — Give a scroll-framed modal room instead of its content minimum
- `0ff9dacfec25e8c4f1f6851df1e7bb0faaa41102` — Record the v0.6.1 rebuild's verified artifact facts
- `4adeae61252d686d20ee280f1e6e0a5b3b345636` — Aim the v0.6.1 checklist at what actually changed

## Gates

- Full `bash run_tests.sh`: 119 suites green (118 previously + `test_modal_responsive_frame`).
- `test_modal_responsive_frame`: 6/6. Verified it fails 3/6 against the pre-fix code,
  reproducing the exact 1152x648 frame.
- `python3 AGENT/Docs/check_docs.py`: all 43 checks green.
- `bash scripts/session_closeout.sh`: audit-cadence, session-claims, evidence-matrices
  all pass.
- GDScript format and lint: green over 272 files.
- Container `bash scripts/test-tools.sh`: green. Root `pytest`: 111 passed, 0 failed —
  including the two that were failing before this session (a track.py caller-compat
  assertion and the hardcoded release-source version).
- Playwright album regenerated from HEAD: 133/133.
- Bundle guard checks verified by construction: supplying a debug artifact as the
  release one, a version disagreeing with the packed stamp, and a schema-1 manifest are
  each refused. The stale-export guard was verified by corrupting a manifest's
  source_sha and confirming the harness refuses to run.

The v0.6.1 checklist now leads with build identity and names the exact stamp to expect,
adds an explicit "windows are no bigger than they need to be" check for the regression
no automated gate can see, and points lockout reproduction at the debug executable.

Both branches are pushed. `V061-UI-PLAYWRIGHT-RESPONSIVE-2026-08-02` is `in_review` on
the docs line. Note for anyone reading the tracker from a feature branch: the container
checkout's working copy of `coordination/tasks.json` has diverged from
`origin/agent/staging-area` (324 rows vs 318) because ten commits on
`agent/from-staging-area/playwright-harness` edited it directly on a code branch. The
docs line is authoritative; the docs-guard hook refuses those edits now.

## Next

Native Windows validation of the rebuilt bundle, against the v0.6.1 checklist. Confirm
the startup BUILD STAMP reads `version=0.6.1` before recording any result — the previous
bundle's did not. Do not tag v0.6.1 until that pass is accepted; the tag must point at
the exact commit in the stamp.
