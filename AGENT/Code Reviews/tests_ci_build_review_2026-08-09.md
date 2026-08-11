# Pillar 4 — Tests, CI & Build Review (2026-08-09)

> **Pillar:** 4 — Tests, CI & Build
> **Procedure:** `AGENT/Review Procedures/04_Tests_CI_Build_Pillar.md`
> **Snapshot:** `agent/integration` at `41c0e5fc1116a9a01aed3afc48dbc92f021d018d`
> **Previous review:** `AGENT/Code Reviews/tests_ci_build_review_2026-07-15.md`

**Score:** 8/10

## Executive summary

The safety net is materially broader than on July 15: 135 Godot suites pass, the
gdtoolkit format/lint gate is pinned and active, hook/CI parity for analyzer and scene
integrity is repaired, and both configured export targets produced fresh artifacts.
The principal gap is no longer missing tests but missing test discovery: three Python
infrastructure suites and the browser controller-shell suite all pass when invoked
directly, yet none is called by a required local or GitHub gate. The old inventory
migration script is also an unsafe stale contributor trap. No Critical or High finding
was found.

## Baseline results

- `python3 AGENT/Docs/check_docs.py`: **PASS**, 43/43 checks, exit 0.
- `bash run_tests.sh`: **PASS**, 135/135 Godot suites, 0 failed, in approximately
  30 seconds with 8 workers. Its schema-trial precheck also passed 5 valid packs and
  matched all 8 negative-contract errors.
- `python3 -m pytest tools/godot-analyzer-mcp/tests/`: **PASS**, 12/12 in 0.16s.
- `python3 -m unittest scripts.ci.test_check_session_commit_claims
  scripts.ci.test_check_shared_infrastructure_sync
  scripts.ci.test_release_source_branch`: **PASS**, 23/23 in 2.783s.
- `node --test tools/web/controller_shell.test.mjs`: **PASS**, 28/28 browser-shell
  assertions in 1.15s.
- `bash scripts/ci/check_gdscript_style.sh`: **PASS**, 313 tracked GDScript files;
  gdformat found no changes and gdlint found no problems.
- `python3 scripts/ci/check_scene_integrity.py`: **PASS**, 23 scene-attached scripts.
- RNG and evidence-matrix guards: **PASS**.
- Fresh Web debug export: **PASS**, exit 0 in 3s; 35,754,592-byte WASM and
  1,794,084-byte PCK plus shell/PWA assets.
- Fresh Windows debug export: **PASS**, exit 0 in 4s; 102,451,760-byte executable.
- `docker compose config --quiet`: **not run** because Docker is absent from this
  audit environment. This is an environment limitation, not evidence of a project
  defect.

The shared Session 1 baseline independently recorded the same 43/43 documentation and
135/135 suite result. This pillar reran the required focused gates and exports against
the same pinned source snapshot.

## Issues

### Medium — 51 infrastructure and browser assertions are not in any required gate

Evidence: `.github/workflows/tests-pr.yml:19-39`,
`.github/workflows/tests-push.yml:19-39`, `scripts/hooks/pre-commit:63-105`, and
`run_tests.sh:55-86` enumerate the required non-Godot checks. None invokes
`scripts/ci/test_check_session_commit_claims.py`,
`scripts/ci/test_check_shared_infrastructure_sync.py`,
`scripts/ci/test_release_source_branch.py`, or
`tools/web/controller_shell.test.mjs`. The browser test is explicitly identified as
the companion contract by `scripts/tests/test_controller_service.gd:7`.

All four suites pass when invoked directly (23 Python tests plus 28 browser
assertions), so the defect is discovery rather than a current red test. A regression in
the session-claim ledger, staging/integration infrastructure-sync guard, release-source
guard, or JavaScript input bridge can therefore merge while both GitHub workflows and
the documented full test command stay green.

Recommended fix: add one stdlib infrastructure-test command and one `node --test`
command to both workflows and the versioned pre-commit hook, or make a single fast
tooling runner the shared source called by all three. Keep `run_tests.sh` focused on the
Godot suite only if the configured workspace full test command invokes the companion
runner too.

Classification: **deferred/systemic**. The same ungated test files exist on the frozen
v0.7.1 candidate, but every direct test is green and this is not evidence of a candidate
runtime defect or a reason to modify that frozen branch.

### Medium — stale inventory migration tool silently targets an unrelated absolute path

Evidence: `tools/convert_inventory_tres.py:93-104` takes no arguments and walks the
hard-coded `/workspace/data`, not this repository's `data/` directory. It then calls
`convert_file()` for every `.tres`; `tools/convert_inventory_tres.py:63-88` changes
`load_steps`, injects an ext-resource with a fixed id, and overwrites each file in
place. It has no dry-run, backup, validation, rollback, or tests. No live script or
guide references the tool; only the Pillar 4 procedure names it.

On this workspace layout `/workspace/data` does not name Project Prometheus data, so a
contributor following the script's module description gets either a false-success
`Converting 0` result or mutations outside the intended checkout if that directory is
later created. The fixed ext-resource id can also collide with an existing resource.

Recommended fix: archive/delete the completed migration tool, or turn it into a tested
CLI that requires an explicit validated root, defaults to dry-run, allocates resource
ids safely, and fails if no eligible files are found.

Classification: **integration only / systemic tooling debt**. The file is present on
the frozen candidate but excluded from both exports by `export_presets.cfg:10,82`; it
cannot affect the shipped executable.

## Coverage gap table

| System | Meaningful tests? | Evidence / remaining qualifier |
|---|---:|---|
| Turn flow, AI and hotseat handoff | Yes | `test_turn_manager`, `test_enemy_ai`, including Hotseat phase behavior. |
| Combat, forecast, targeting and skills | Yes | `test_combat`, preview/targeting suites, skill registry/handler suites. |
| Save/load, suspend, Retry and Rewind | Yes | Codec, integrity, policy, failure-injection, import-budget, suspend and rewind suites. |
| Promotion, reclass and pair-up | Yes | Dedicated UI, registry, resolver, context and end-to-end suites. |
| Campaign/package activation and zero-content boot | Yes | Catalogue, installer, exporter, Tier-2, schema, malformed-package and zero-content suites. |
| Map objectives, fog, terrain and encounter results | Yes | GameMap, encounter, battle-result, fog and terrain suites. |
| Display, input, responsive and mobile UI | Yes, headless-qualified | Settings, input, responsive, text-entry, touch and modal suites; real Windows/phone visual acceptance remains playtest evidence. |
| Analyzer/parser tooling | Yes and gated | 12 pytest/unittest-compatible tests run in both workflows and pre-commit. |
| Process/release Python tooling | Yes, **not gated** | 23 passing tests exist but are undiscovered by required gates. |
| Web controller shell | Yes, **not gated** | 28 passing Node assertions exist but are undiscovered by required gates. |
| Conditions | No meaningful behavior yet | `ConditionManager.gd` remains an explicit M8 no-op stub; not a new uncovered shipped critical path. |

No uncovered implemented critical path meeting the procedure's High threshold was
found. Several presentation-only scripts are exercised through scene or integration
suites rather than filename-matched unit tests; that is not by itself a coverage gap.

## CI and hook findings

- Both GitHub workflows gate pinned gdtoolkit, documentation, RNG, analyzer tests,
  scene integrity and the complete headless suite without `continue-on-error`.
- The versioned pre-commit hook now runs analyzer and scene-integrity checks, closing
  the prior audit's parity finding. It also runs the same style gate as CI.
- The hook additionally runs session claims and evidence matrices, while CI does not;
  the missing unit-test discovery above is the actionable mismatch.
- The pre-push destination, cadence, claim, evidence and infrastructure-sync guards
  are present. Their implementation tests are not transitively run by the hook.

## DoD#2 enforcement gaps

- The master procedure's GDScript lint/format item is no longer a real backlog item:
  `requirements-dev.txt`, both workflows, the hook and
  `scripts/ci/check_gdscript_style.sh` now enforce it. Pillar 2 should correct the
  stale procedure status in a later documentation pass; this audit remains report-only.
- Procedure-folder path scanning and anchored score enforcement for every historical
  pillar report remain the explicitly documented lower-priority backlog.
- New enforcement candidate: discover every checked-in `scripts/ci/test_*.py` and
  `tools/**/*.test.mjs` suite from one required tooling-test runner so future tests
  cannot be orphaned in the same way.

## Build and export findings

- Windows and Web debug exports both completed from the pinned tree. The export preset
  excludes `AGENT/**`, tests, fixtures, `scripts/tools/**` and root `tools/**` on both
  platforms.
- The integration preset and setup guide consistently identify v0.7.0. The frozen
  v0.7.1 candidate has its own baked release metadata; that intentional branch split is
  not a version-drift finding.
- `project.godot` loaded successfully through tests and both exports; its autoload and
  input wiring is heavily exercised by the suite.
- Docker configuration was inspected but could not be parsed or built because the
  `docker` executable is absent. No Docker change occurred in the audited delta.

## Positive observations

- The Godot suite grew from 98 to 135 suites while staying green and under one minute.
- The previously missing gdtoolkit gate is fully landed, pinned, and green across 313
  tracked GDScript files.
- The prior analyzer/scene-integrity hook parity issue is fixed.
- Fresh Web and Windows exports succeeded, and the earlier root `tools/**` packaging
  leak remains fixed on both presets.
- High-risk save import budgets, atomic save failures, schema registries, mobile input,
  fog/terrain and multi-map campaign flow now have focused negative-path coverage.

## Prioritized action plan

1. Put the 23 Python infrastructure tests and 28 browser-shell assertions behind a
   shared required tooling-test gate.
2. Retire or harden `tools/convert_inventory_tres.py` before anyone reuses it.
3. Update the master procedure's enforcement backlog to mark gdtoolkit landed and add
   tooling-test discovery as a candidate.
4. Preserve both-platform export smoke checks in release verification and complete
   platform-native visual/input acceptance through the existing playtest line.

## Delta vs previous review

- Score remains **8/10**: the suite and gates improved substantially, but newly added
  infrastructure/browser tests are not yet part of those gates.
- Improved: 37 additional Godot suites (98 -> 135) cover zero-content schemas, save
  failure/import limits, responsive/mobile input, terrain/fog, encounter results and
  multi-map fixtures.
- Fixed: analyzer and scene-integrity checks now run in pre-commit as well as CI.
- Fixed: pinned gdtoolkit formatting/lint enforcement is present and green.
- Fixed/retained: root `tools/**` remains excluded from Windows and Web exports.
- Newly surfaced: 51 passing non-Godot assertions are checked in but undiscovered.
- Newly surfaced by the procedure's required one-off-tool review: the inventory
  converter is stale, hard-coded and unsafe to reuse.

## Procedure friction

- The procedure still says the tooling suite needs pytest and that missing pytest is a
  finding, while the analyzer suite is deliberately stdlib-compatible and both GitHub
  workflows correctly run it without pytest. Pytest was available here, so this did
  not block the audit, but the wording no longer describes the gate's dependency.
- The master procedure still lists gdtoolkit as unlanded even though it is now enforced.
- `run_tests.sh` prints no aggregate assertion count or elapsed time. Suite/failure
  counts are reliable; the runtime above is a wall-clock observation.
- The prescribed Docker check cannot run in this container because Docker is absent.
  Export validity was independently checked with Godot itself.
