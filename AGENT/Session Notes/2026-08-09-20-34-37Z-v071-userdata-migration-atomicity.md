# Session Notes — 2026-08-09-20-34-37Z-v071-userdata-migration-atomicity (v071-userdata-migration-atomicity)

## What was done

- Changed legacy user-data carry-over to copy each owned root into a staging
  path and rename it into place only after the complete root succeeds.
- A nested copy error now removes the partial staging tree and prevents the
  global completion marker from being written, allowing the next launch to
  retry safely.
- Added a real-filesystem regression that injects a failure after one nested
  write, proves no partial destination or marker survives, then proves the next
  run copies both files and completes.
- Updated the architecture contract, display/settings guide, and roadmap status.

## Factual Git state

- Branch: `agent/from-integration/v071-userdata-migration-atomicity`
- HEAD: `3b8284736fab9aa7e33011f5da91c406e003b9f8`
- Task merge base: `2957d65c905c285690f3b88f5c4bf31086399d26`

## Commits

- `3b828473` Make legacy user-data migration retryable

## Checks

- `full`: `bash run_tests.sh` at `3b8284736fab`

## Decisions and context

- Per-root atomicity is sufficient and preserves useful progress: roots already
  committed before a later root fails remain protected by the existing
  no-overwrite rule, while only the failed root retries.
- The frozen `agent/playtest-release-v0.7.1` candidate remains untouched at
  `0db30fd1`; remediation continues on feature branches from integration.
- `GDD_10` labels this as a release-repair area rather than citing the workspace
  task id because its documentation guard only admits ids in the local Project
  Control Plane. The canonical row remains in workspace `coordination/tasks.json`.

## Next session

Merge this green branch into the then-current `agent/integration`, then start the
approved redesign on `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`. Do not add a
fifth Windows interception hook: the v0.7.0 and v0.7.1 returns both showed zero
guard telemetry. Replace the two-stage Escape contract with a game-owned filename
modal before opening the picker, where FileDialog Escape keeps its conventional
single cancel meaning. Retire `FileDialogInputGuard` Escape interception with focused
headless coverage and plan a Windows validation pass for the resulting event order.

After that, continue `V071-RETURN-TRIAGE-2026-08-09` with
`IMPL-ZERO-CONTENT-EXPORT-GATE`, only after replacement-pack lifecycle evidence is
still green. The ordered source remains
`AGENT/Code Reviews/v071_remediation_handoff_2026-08-09.md`.
