# Session Note - Zero-content export gate

## Branch context

- Branch: `agent/from-integration/zero-content-export-gate`
- Base branch: `agent/integration`
- Base SHA: `9568da88dac86dba9bf4ff13b85cd72a6f112999`
- Coordination Work ID: `ZERO-CONTENT-EXPORT-GATE-2026-08-09`

## What was done

- Re-proved the replacement-pack lifecycle on the current remediation base: real
  fixture export, preflight, install, discovery, selection, activation, and playable
  roster launch pass 6/6.
- Excluded `data/**` from both Windows and Web exports while retaining the checked-in
  tree as editor-only extraction and test input.
- Editor-gated project-data compatibility activation, including package-less legacy
  save loading, so headless development fixtures remain usable but exported players
  cannot enter that path.
- Removed New Game's package-less fallback to `res://data`; a run without package
  identity now fails closed.
- Added a permanent export-boundary regression and updated the data contract, roadmap,
  and zero-content implementation plan.

## Commits

The behavior commit `b123f8ea` implements the player/export boundary. Ownership is
recorded in `AGENT/Session Notes/CLAIMS.tsv`.

## Gates

- Replacement-pack lifecycle: 6 passed, 0 failed.
- Export-boundary regression: passed.
- `bash run_tests.sh`: all 136 suites green at `b123f8ea`.
- Documentation checks, RNG guard, analyzer tests, scene integrity, session claims,
  evidence matrices, and GDScript formatting/lint: green.

## Next

Produce a release export from this branch and inspect the resulting PCK/artifact to
prove no catalogue or playable definition from `data/**` is present. If that artifact
audit is green, commit the evidence, push, merge this branch into `agent/integration`,
and close `IMPL-ZERO-CONTENT-EXPORT-GATE`. Then update the consolidated v0.7.1
remediation row: automated remediation is complete, while the filename modal and the
new content-free build still require the next Windows return.
