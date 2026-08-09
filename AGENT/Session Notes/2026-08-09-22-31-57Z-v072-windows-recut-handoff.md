# Session Note — v0.7.2 Windows remediation recut handoff

## Branch context

- Branch: `agent/playtest-release-v0.7.2`
- Base branch: `agent/integration`
- Base SHA: `61c26bd16043355666a16f197664386aacb970d9`
- Coordination Work ID: `V072-WINDOWS-RECUT-2026-08-09`

## What was done

- Followed the newest session handoff rather than the superseded pre-return palette
  queue. All five v0.7.1 automated remediation items were already on integration.
- Cut a fresh sibling release branch from exact integration head without modifying the
  rejected `agent/playtest-release-v0.7.1` candidate at `0db30fd1`.
- Advanced the governed release identity from v0.7.0 to v0.7.2 across the export preset,
  executable paths, Main Menu label, and environment guide.
- Added the matching playtest build record required by the release-source guard.
- Replaced the stale v0.7.1 checklist with a focused acceptance round for content-free
  launch, replacement-pack discovery/selection/resume, the game-owned filename modal,
  migration retry behavior, and basic Windows/controller smoke coverage.
- Regenerated the docs index and regenerated the Godot class cache after the commit hook
  correctly detected it was missing.

## Commit and gates

- Candidate scaffolding: `0e2b2ebb` (`Prepare v0.7.2 Windows remediation recut`).
- Fast and pre-commit test runs: all 136 suites green.
- Documentation checks, RNG guard, analyzer tests, scene integrity, evidence matrices,
  session claims, and GDScript format/lint: green.
- Commit ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`.

## Next session

Resume on `agent/playtest-release-v0.7.2`. Do not amend v0.7.1 and do not merge new
feature work into this candidate.

1. Commit this session-note/claim record and run the exact-HEAD full check.
2. Push the branch with `scripts/agent-work --repo Project_Prometheus push`.
3. Produce release and debug Windows exports through the normal release-qualified
   exporter; the build record already names this branch.
4. Read back BUILD STAMP `0.7.2/<candidate>` from both executables, record sizes and
   SHA-256 digests, and confirm the release PCK contains no top-level `data/**` entries.
5. Include a known-good replacement-pack archive, this checklist as
   `PLAYTEST_CHECKLIST.md`, `BUILD_INFO.json`, manifests, and `SHA256SUMS.txt` in the
   private tester bundle.
6. Update `playtest_build_v0.7.2.md` from `Candidate preparation` to exported evidence,
   update the tracker, and leave the candidate frozen pending its Windows return.

The remaining gate is native Windows evidence. Do not close
`V071-RETURN-TRIAGE-2026-08-09` or the FileDialog row on headless success.
