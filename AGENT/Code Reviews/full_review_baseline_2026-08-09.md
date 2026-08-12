# Full project review baseline — 2026-08-09

Status: Complete — stable baseline for the 2026-08 full audit.

Last verified: 2026-08-09

Tracker: `FULL-AUDIT-2026-08-2026-08-09`

Handoff: [Full project audit multi-session handoff](full_project_audit_multisession_handoff_2026-08-09.md)

Procedure: [Master Review Procedure](../Review%20Procedures/00_Master_Review_Procedure.md)

## Snapshot contract

- Audit date used by every report in this run: **2026-08-09**.
- Audit branch: `agent/from-integration/full-audit-2026-08`.
- Audited source branch: `agent/integration`.
- **Pinned audited source SHA:** `41c0e5fc1116a9a01aed3afc48dbc92f021d018d`.
- Local and remote-tracking `agent/integration` both resolved to that SHA at the
  opening measurement.
- Audit-branch HEAD before this baseline was written:
  `3ee5cce83e78ee46f1a5521108fa730e603623fd`. Its two commits beyond the pinned
  source contain only the approved audit handoff and its commit-claim record.
- `git status --porcelain` produced no output before the measurements: the tree was
  clean.
- Frozen v0.7.1 candidate (context only, not modified):
  `agent/playtest-release-v0.7.1` at
  `0db30fd17adb83fb7e912c57b7630933c31588d6`.

All pillars must review the pinned source SHA above. Later audit-report commits and
later movement of `agent/integration` do not change that contract.

## Toolchain probe

Every required probe was present and returned exit code 0.

| Tool | Resolved executable | Measured version |
|---|---|---|
| Godot | `/usr/local/bin/godot` | `4.6.3.stable.official.7d41c59c4` |
| Python | `/usr/local/bin/python3` | `Python 3.12.13` |
| pytest | `/usr/local/bin/pytest` | `pytest 9.1.1` |
| gdlint | `/usr/local/bin/gdlint` | `gdlint 4.5.0` |
| gdformat | `/usr/local/bin/gdformat` | `gdformat 4.5.0` |
| GitHub CLI | `/usr/bin/gh` | `gh version 2.97.0 (2026-07-31)` |

Pillars should still use the lowest-dependency runner required by their procedure;
tool availability is not permission to add dependencies or mutate the snapshot.

## Green baseline

Both commands were run directly with their output redirected to separate temporary
logs. Their exit statuses were captured by the invoking shell before the logs were
inspected; no pipeline masked either status.

| Gate | Result | Evidence summary |
|---|---|---|
| `python3 AGENT/Docs/check_docs.py` | **PASS (exit 0)** | All 43 documentation structural checks passed. The class-schema trial also matched 5 valid packs and 8 negative-contract errors; its 10 presentation-name collision groups were reported as advisory, not failures. |
| `bash run_tests.sh` | **PASS (exit 0)** | All 135 suites passed in the normal 8-worker run. |

The baseline is stable. Pillars must not report an unstable-baseline warning and must
not redo these two general gates unless their own procedure requires a narrower probe.

## Tree-completeness map

The preflight found all visible top-level directories named by master-procedure §2.
Hidden generated caches were also recorded so they are not mistaken for source.

Some top-level containers intentionally hold more than one pillar's material (`AGENT`
and `scripts` in particular). Exact ownership is therefore assigned below by path rule;
no individual path is assigned to two pillars.

| Top-level path | Exact owner rule |
|---|---|
| `AGENT/` | Pillar 2 owns `AGENT/GDD/**`, `AGENT/Docs/**` guides/governance/decisions/registers/design/plans and documentation review output. Pillar 5 owns `AGENT/Session Notes/**`, playtest/process/history evidence, prior reviews as historical evidence, and `AGENTS.md` adherence. Review-procedure files and new audit reports are control inputs/outputs, not product findings. |
| `Draft UI assets/` | Pillar 3. |
| `assets/` | Pillar 3, including every resource, import and sidecar below it. |
| `builds/` | Pillar 4 as generated/export evidence; it had no tracked files. |
| `data/` | Pillar 3 for every `.tres` and authored data resource; any executable `.gd` helper would follow the Pillar 1 code rule. |
| `scenes/` | Pillar 3 for scenes/resources and autoload wiring; attached runtime `.gd` code follows Pillar 1. |
| `scripts/` | Pillar 1 owns non-test runtime GDScript. Pillar 4 owns `scripts/tests/**`, `scripts/ci/**`, `scripts/hooks/**`, test runners and analyzer/one-off tooling. |
| `test_fixtures/` | Pillar 4. |
| `tools/` | Pillar 4, including analyzer MCP code and its tests. |
| `ui_previews/` | Pillar 4 as generated analyzer/inspection output; it had no tracked files. |
| `.godot/` | Generated, ignored Godot cache; not audited as source. Pillar 4 owns import/cache behavior if it becomes relevant. |
| `.pytest_cache/` | Generated, ignored test cache; not audited as source. Pillar 4 owns runner/cache behavior if relevant. |
| `.github/` | Pillar 4. |

### Tracked root files

| Pillar | Root files |
|---|---|
| Pillar 2 — Documentation | `README.md` |
| Pillar 3 — Scenes, data and assets | `default_bus_layout.tres` |
| Pillar 4 — Tests, CI, build and tooling | `.dockerignore`, `.env.example`, `.mcp.json`, `Dockerfile`, `docker-compose.yml`, `export_presets.cfg`, `gdformatrc`, `gdlintrc`, `project.godot`, `requirements-dev.txt`, `run_tests.sh` |
| Pillar 5 — Process and history | `.gitattributes`, `.gitignore`, `AGENTS.md`, `CLAUDE.md` |

No visible top-level directory or tracked root file remains unowned. Root symlink scan
found none.

## Prior-report discovery

Each pillar receives the glob, not only the resolved result. The pillar must confirm
its own comparison source against the pinned snapshot.

| Area | Required glob | Resolved comparable prior report |
|---|---|---|
| Tests, CI and build | `AGENT/Code Reviews/tests_ci_build_review_*.md` | `AGENT/Code Reviews/tests_ci_build_review_2026-07-15.md` |
| Code | `AGENT/Code Reviews/code_review_*.md` | `AGENT/Code Reviews/code_review_2026-07-15.md` |
| Scenes, data and assets | `AGENT/Code Reviews/data_assets_review_*.md` | `AGENT/Code Reviews/data_assets_review_2026-07-15.md` |
| Documentation | `AGENT/Docs/documentation_review_*.md` | `AGENT/Docs/documentation_review_2026-07-15.md` |
| Process and history | `AGENT/Code Reviews/process_history_review_*.md` | `AGENT/Code Reviews/process_history_review_2026-07-15.md` |
| Full rollup | `AGENT/Code Reviews/full_review_rollup_*.md` | `AGENT/Code Reviews/full_review_rollup_2026-07-15.md` |

There was no prior `full_review_baseline_*.md` file.

### Resolution caution

The code glob also matches specialized reports such as
`code_review_v0.3.0_release_delta_prep_2026-07-07.md`. Plain lexical sorting makes
that file appear after `code_review_2026-07-15.md`, even though it is older and is not
the preceding full-audit code pillar. The comparable prior above was resolved by
report purpose and audit date, not by taking the lexically last filename. Pillar 1
must preserve that distinction when computing its history delta.

## Session 1 findings and procedure friction

- No product finding was opened: both baseline gates are green.
- The handoff named tracker row `FULL-AUDIT-2026-08-2026-08-09`, but the container
  checkout's local `coordination/tasks.json` did not contain it. The canonical docs
  line did contain it: the supported add-task helper rejected a second registration
  as an overlap with that exact row. The canonical row was retained and updated; no
  duplicate was created. Pillar 5 should consider this local/remote tracker-visibility
  behavior as process evidence, not a product finding from Session 1.
- Master §3 says to map every top-level directory to exactly one pillar, while master
  §2 explicitly divides `AGENT/**` and `scripts/**` between pillars. This baseline
  resolves the ambiguity with mutually exclusive path rules. Pillar 5 should record
  the wording friction; it did not leave audit scope unowned.
- Prior-report globs need semantic resolution, as demonstrated by the code glob above.

## Next session

Session 2 follows
`AGENT/Review Procedures/04_Tests_CI_Build_Pillar.md` completely and writes
`AGENT/Code Reviews/tests_ci_build_review_2026-08-09.md`. It must audit the pinned
source SHA in this baseline, use the prior-report glob above, classify v0.7.1
applicability, and exit with an anchored `**Score:** N/10` report.
