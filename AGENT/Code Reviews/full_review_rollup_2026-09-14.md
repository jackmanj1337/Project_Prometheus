---
Role: dated
---

# Full Project Audit — Rollup (2026-09-14)

> Five-pillar workspace audit under `AGENT/Review Procedures/00_Master_Review_Procedure.md`
> (revision of 2026-09-13). Read-only: no remediation is implemented here.

**Audit date:** 2026-09-14
**Audited commit:** ad2e6be729013f46a3978269c8ea0f6248f81aad

**Overall health:** 4/10

Rounded mean of the five pillar scores: 6/10 (6.0). The headline is the lowest pillar,
per Master §6, and is held down by one demonstrated required-gate failure whose real
baseline is nonetheless green.

## 1. Snapshot and baselines

| Repository / authority | Ref | Commit | State |
|---|---|---|---|
| Project_Prometheus (primary) | `agent/integration` | `ad2e6be729013f46a3978269c8ea0f6248f81aad` | clean, level with origin; tree `7e37e4da3b841f235baba05367d0ce18e0b92145` |
| Project_Prometheus_Campaign_Pack_0 | `agent/from-proving-grounds-public-pack/v079-free-roam-validation-pack` | `0ed6143fd91f818f4208da7fc3f5245cd2f46c04` | clean; deliberately not `main` (below) |
| Project_Prometheus_Campaign_Pack_FE | `main` | `99695b7619f86acec872a0dad0033e6753981fee` | clean; tree `d83ce9de64157d11d780b2ef75d9235f30556baf` |
| Project_Prometheus_Container | `agent/staging-area` | `49dd69be21bac60b2318fabedc3950d41cb7a952` | clean at pin; later commits touch tracker/handoff paths only |
| Review procedure | engine `agent/integration` / `agent/staging-area` | `1f86dfa0ee599c828711f38d198628529f89aa86` / `520630294ef2bd01af418724eed4fa9b766afc31` | procedure text identical on both lines |
| Report route | `agent/from-staging-area/full-audit-september-reports` | from engine staging `ed4a8662b755b5c0a86f49dc7036c59d099fd346` | publication only; not the audited snapshot |

**Pack_0 is pinned off `main` on purpose.** Its `main` has no Proving Grounds pack, and
`check_pack_freshness.sh` discovers packs from the working tree, so a `main` checkout
does not fail the gate — the pack silently leaves it. Promotion is
`V079-PUBLIC-PACK-PROMOTION-2026-08-24` (in_review).

| Baseline (Master §3.4) | Result | Evidence |
|---|---|---|
| Engine `bash run_tests.sh` | PASS — 200 Godot suites, no SKIP lines, required non-Godot runner green; 55.1 s at registration | exact-tree receipt `audit/check-receipts/Project_Prometheus-full.json` (head/tree above, exit 0, 2026-09-14T18:12Z); lead log `/tmp/full-audit-2026-09-14-engine.log` |
| Engine `check_docs.py` | PASS — all checks green, including check 11 coverage map | `/tmp/full-audit-2026-09-14-docs.log` |
| `check_pack_freshness.sh` | PASS — 2 packs validate | tracker row `FULL-AUDIT-2026-09-14` |
| Pack_FE `pytest` | PASS — 32 passed, 14.45 s | exact-tree receipt `audit/check-receipts/Project_Prometheus_Campaign_Pack_FE-full.json` |
| Pack_0 `pytest` | PASS — 6 passed | recorded at registration; no raw log retained |
| Container `pytest tests/ -q` | PASS — 201 passed, 2 skipped | recorded at registration; no raw log retained |
| Tooling probe (§3.3) | Godot 4.6.3.stable.official.7d41c59c4, Python 3.12.14, Node v24.20.0, gdformat 4.5.0, gdlint 4.5.0 | — |

`/tmp` logs are local to this container and ephemeral; receipts under `audit/` are the
durable identities. Suite runs were serialized: `test_registry_manager` waits on frame
budgets while spawning two headless Godot processes, and a concurrent second suite
starves it (observed once on 2026-09-14, green alone).

## 2. Pillar reports

- [Code](code_review_2026-09-14.md)
- [Documentation](../Docs/governance/documentation_review_2026-09-14.md)
- [Scenes, Data & Assets](data_assets_review_2026-09-14.md)
- [Tests, CI & Build](tests_ci_build_review_2026-09-14.md)
- [Process & History](process_history_review_2026-09-14.md)

## 3. Execution, coverage and omitted scope

**Execution.** Codex CLI led registration, baselines, inventory and eight bounded
read-only `gpt-5.6-luna` assignments: W1/W4 harness, receipts and CI; W2/W5/W8 code
journeys (pack import/activation, New Game selection, save/load/migration, editor save
and working-copy import, phase-start condition/Renewal transactions); W3/W6 authored
content and wiring; W7 documentation and recent process.
Claude Code (Opus 5) took over as lead for closeout. The worker returns lived in the
Codex session and are not retained; the closeout lead did **not** re-read them.
Instead, every Critical, High and Medium claim below was re-read at the pinned SHAs,
and the two runtime reproductions were re-read from their preserved logs.

**Path assignment** (Master §2; assignment is responsibility, not review credit):

| Repository | Tracked | P1 Code | P2 Docs | P3 Content | P4 Tests/Build | P5 Process | Excluded by protected name |
|---|---:|---:|---:|---:|---:|---:|---:|
| Project_Prometheus | 3,087 | 251 | 757 | 793 | 624 | 661 | 1 |
| Pack_0 | 158 | 0 | 2 | 152 | 4 | 0 | 0 |
| Pack_FE | 3,167 | 0 | 3 | 3,151 | 13 | 0 | 0 |
| Container | 302 | 0 | 9 | 0 | 143 | 149 | 1 |

Engine assignment is check 11's map, with zero unassigned paths. Pack rules: `packs/`
and `assets/` → 3; `tests/`, `tools/`, `.github/`, `.gitignore` → 4; README/CREDITS/NOTICE → 2.
Container rules: `scripts/ hooks/ tests/ tools/ config/ docker/ .github*/ .devcontainer/`,
`coordination/*.py` and root configuration → 4; `docs/`, `README.md`,
`godot_prometheus_setup.md` → 2; `AGENT/` (memory, handoff, frozen notes), `audit/`,
`coordination/` data, `AGENTS.md`, `repo/AGENTS.md`, `repo/CLAUDE.md` → 5. The container's
excluded path is `config/tool-versions.env`, which matches the `*.env` protected pattern
and was not opened. `.secrets.example/github.env.example` does not match any pattern.
It was assigned to 4 by name and not opened.

Worktrees: seven linked Project_Prometheus checkouts under `repo/` and one Pack_0
checkout under `.agent-worktrees/` are the same repositories. They are counted once.

**Semantic coverage was sampled.** The pillar reports list what was inspected. The
largest omissions are:

- the full combat/AI matrices, every migration vocabulary and editor export/reimport branch;
- performance, native rendering and native Windows behaviour of any kind;
- visual review of binary art, fonts and audio (the bulk of FE's 3,151 content paths);
- every test assertion and workflow branch;
- an exhaustive 30-day commit/claim audit and all-branch containment.

No exports, Docker rebuilds, signing inspection or release promotion were performed.
Container-rendered or headless evidence here does not stand in for native acceptance.

## 4. Scorecard

| Pillar | Score | Versus 2026-08-09 |
|---|:---:|---|
| 1 — Code | 5/10 | 6 → 5; the editor save boundary is new verified debt. August's between-map resume finding is repaired |
| 2 — Documentation | 6/10 | unchanged number, different findings; not a trend claim |
| 3 — Scenes/Data/Assets | 8/10 | 10 → 8, but not comparable: August claimed completeness, this is an explicitly sampled workspace review |
| 4 — Tests/CI/Build | 4/10 | 8 → 4; a demonstrated broken required gate (Critical bar), although the real baseline is green |
| 5 — Process/History | 7/10 | unchanged number; session-note gates retired since, so the scope differs |
| **Overall health** | **4/10** | lowest pillar; rounded mean 6/10 (6.0, August 7.4) |

August's rollup covered the engine alone. This one covers the workspace. Treat the
deltas as indicators, not measured trends.

## 5. Executive assessment

The engine is in better shape than the headline implies. There are 200 green suites,
none of which skip. A staged installer validates packs before promotion. Registry
activation layers pack entries over engine defaults and is atomic. Between-map resume
now rolls back completely. Save slot and index replacement are staged together. The
documentation checks are green and the process leaves a traceable residual for every
accepted-but-unmeasured item.

The score is low because of one pattern, and it is August's pattern again: **a failure
is detected inside a component and then lost at the next boundary out.** The clearest
case is `run_tests.sh`. It fixed exactly this for the non-Godot runner at `:39-43`, with
a comment explaining the incident. Fifty lines later, at `:97-100`, it calls the schema
validator it names a "required gate" without checking the result. The editor is a
second case: a document declares itself clean before the disk has accepted the write.
Neither is a crash today. The first means a real schema regression would ship green.
The second means an author can close a document after a refused save without being
warned.

## 6. Cross-pillar findings

### CROSS-1 — Failure status dropped at an outer boundary (Critical, recurring)

**Owners:** Tests (gate), Code (editor). **Supporting:** Process.

- **Gate.** `run_tests.sh:97-100` ignores `check_trial_fixtures.py`'s exit status, and
  the runner has no `set -e`. Lead fault injection copied the real runner and
  classifier, used a validator that exits 1 and a passing Godot stub. The output was
  `PASS: all suites green`, exit 0 (`/tmp/full-audit-schema-gate-probe.log`). The real
  fixtures pass at the pin. → `AUDIT-SCHEMA-GATE-2026-09-14`.
- **Editor save.** `CampaignEditorShell.save_active_document:380` calls
  `EditorDocument.save:293`, which clears the overlay and notifies clean. Only then
  does `CampaignEditorScreen._on_shell_document_saved:483` write. The comment at
  `:473-476` says the write happens "BEFORE the signal so a listener never sees a save
  the disk has not taken". That is true of the screen's signal, but the document has
  already gone clean. On refusal, `EditorDocumentSet.close:71` closes with no
  confirmation. The probe logged `dirty=true → refused → dirty=false, retained_value=edited
  → close outcome=closed` (`/tmp/full-audit-editor-save-probe.log`). Separately,
  `EditorPackWriter.write:69-99` writes documents one at a time and keeps going after
  errors, so a late failure leaves earlier files on disk with the catalogue unchanged.
  → `AUDIT-EDITOR-SAVE-ATOMICITY-2026-09-14` (High).
- **Suspected, not confirmed.** `GameState.configure_suspend_resume:370-412` activates
  content before later refusals. Its between-map counterpart has explicit rollback. The
  worker's proposed triggers are already rejected by `SaveData.validate()`, so no
  reachable failure has been shown. → `AUDIT-SUSPEND-ROLLBACK-2026-09-14`: prove it or reject it.

August's shared remedy still applies: test `activate → final consumer → injected
failure → complete rollback` at the outermost boundary, not the component's own.

### CROSS-2 — Identities narrower than what they identify (Medium)

**Owners:** Tests (receipts), Code (preferences).

- An exact-tree receipt binds the primary head/tree/command/status
  (`check-receipt.py:117-126`, `workflow_core.py:77-102`). It then runs against the
  *live* sibling packs (`:72`), so it stays valid after its authored inputs change.
  `repo.parent` is also the wrong sibling root for a linked worktree placed elsewhere,
  and `adopter_pack.gd` then SKIPs as ABSENT. → `AUDIT-SIBLING-RECEIPT-2026-09-14`.
- New Game preferences compare and store only campaign/id/version
  (`NewGameScreen.gd:460-465`, `SaveManager.gd:811-828`). Two same-version builds with
  different fingerprints are legal, so the preference can reselect the wrong build.
  → `AUDIT-CAMPAIGN-PREFERENCE-IDENTITY-2026-09-14`. The same row investigates
  `DataManager.gd:744-770`, whose diagnostic dedupe key omits fingerprint and source.

### CROSS-3 — Parallel lists that drifted apart (Medium)

**Owners:** Tests (CI), Documentation (GDD).

- Container `tool-tests.yml:18-40` filters `tools/playwright/lib/**`, while
  `hooks/pre-push:142` and `scripts/test-tools.sh:35` cover `tools/playwright/*`. The
  workflow's own comment says the lists mirror each other. A change to a root-level
  driver runs the local gate but no CI. → reopened `NODE-TEST-DISCOVERY-2026-09-12`
  (workflow edit needs owner approval).
- `GDD_01_Runtime_Contracts.md:1030-1034` still says any pack registry entry replaces
  the engine catalogue, but `DataManager.gd:541-552` layers (`PACK-REGISTRY-LAYERING-2026-09-01`,
  completed). `GDD_01:635-639,1037-1040` and `GDD_10_Roadmap.md:89-94` still name the
  closed legacy-removal row as the release gate, where the residual is
  `V0719-RENEWAL-SUSPEND-CELL-2026-09-14`. → `AUDIT-RUNTIME-DOC-RECONCILE-2026-09-14`.

### Not new, recorded so it is not re-derived

- Promotion edges are an extraction gap (`extract_proving_grounds_pack.gd:281-284,315-327`),
  owned by `FE-PACK-CLASS-ADVANCEMENT-2026-08-31` and `IMPL-ZERO-CONTENT-BASE-PACK`.
- The v0.7.19 played commit and tagged commit differ, owned by
  `V0719-TAG-PLAYED-COMMIT-MISMATCH-2026-09-14`. No retag is authorized.
- The editor shipped in an accepted release without being opened, so every `EDITOR-*`
  row still owes native acceptance. The editor save finding makes naming the editor in
  the next checklist more urgent, not less.
- Rejected claims: Project Control Plane is not obsolete
  (`RETIRE-CONTROL-PLANE-CATALOGUES-2026-08-23`), and successful activations do not
  demonstrably collapse diagnostics.

## 7. Prioritized actions

| # | Action | Severity / effort | Task | Line | Depends on |
|---:|---|---|---|---|---|
| 1 | Check the schema validator's exit status in `run_tests.sh` and exercise its rejection path. Runner infrastructure, so it lands on `agent/integration` **and** `agent/staging-area` | Critical / small | `AUDIT-SCHEMA-GATE-2026-09-14` | engine | — |
| 2 | Keep a document dirty until the writer succeeds. Make the pack writer's document + catalogue write all-or-nothing. Test refusal and late catalogue failure | High / medium | `AUDIT-EDITOR-SAVE-ATOMICITY-2026-09-14` | engine integration | — ; before the next checklist names the editor |
| 3 | Correct the GDD registry-layering and native-gate prose in place | Medium / small | `AUDIT-RUNTIME-DOC-RECONCILE-2026-09-14` | engine staging | — |
| 4 | Add the root Playwright path to the CI filter | Medium / trivial | `NODE-TEST-DISCOVERY-2026-09-12` | container | owner approval for `.github/workflows/**` |
| 5 | Bind sibling inputs into receipts; resolve siblings correctly from linked worktrees | Medium / medium | `AUDIT-SIBLING-RECEIPT-2026-09-14` | container staging | — |
| 6 | Carry fingerprint through New Game preferences; check the diagnostic dedupe key | Medium / small | `AUDIT-CAMPAIGN-PREFERENCE-IDENTITY-2026-09-14` | engine integration | — |
| 7 | Trace a reachable late suspend-resume refusal, or reject the candidate | Suspected / small | `AUDIT-SUSPEND-ROLLBACK-2026-09-14` | engine integration | — |

Item 1 comes first because a broken gate hides every other regression. Item 2 comes
before any editor acceptance round, so the tester does not measure a save that lies.
Items 3–7 are independent and none blocks another. All seven are unassigned.

## 8. Regression watch (August actions)

- **Pack discovery (August P1):** the import/activation path was reviewed and no recurrence found in the sample.
- **Campaign resume atomicity (P2):** fixed for between-map resume (`V071-CAMPAIGN-RESUME-ATOMICITY-2026-08-09`, completed). Suspend-resume is the open candidate above.
- **User-data migration atomicity (P3):** not rechecked.
- **FileDialog native Escape (P4):** the documentation is repaired and Screens/Panels now describes native pickers.
- **Zero-content boundary (P5):** `IMPL-ZERO-CONTENT-BASE-PACK` is in progress; not rechecked.
- **Infrastructure/browser test discovery (P6):** repaired by the required non-Godot runner. This is **regressed in kind**: the schema call is a second unchecked status, and the CI filter lags the widened Node scope.
- **Inventory converter (P7):** not rechecked.
- **Lifecycle authority (P8):** repaired. OPEN-11 was not rechecked.
- **Process tooling (P9):** claim reachability and `audit_cadence.py` exist, and session notes are retired. The cadence still **regressed**: 36 days and 1,039 commits since the last rollup, against about 4 weeks or 30 commits.

## 9. Procedure friction and tooling recommendations

These are recommendations only; none adds a mechanism.

1. **A mid-audit lead handoff loses the worker returns.** §4 keeps returns in agent
   responses. The tracker row's reference carried enough to finish, but the closeout
   lead could only re-verify against source. Recommend that §4 require the lead to fold
   each accepted or rejected worker claim into the row reference as it is reconciled.
   Codex largely did this already.
2. **Registering report paths before they exist fails `check_tasks.py`** ("claim
   missing") until the report branch is pushed. Expected, but noisy. §3.1 should say to
   claim report paths at publication, not at registration.
3. **Receipts carry no raw log path**, so the pack and container pass counts are
   inherited numbers. Recommend recording a log path in the existing receipt schema
   (this repairs a checker, it does not add one). It overlaps action 5.
4. **Protected-name matching is imperfect both ways.** `config/tool-versions.env` is
   excluded even though CI asserts on it, and `.secrets.example/*.env.example` is not
   matched. Note both in §2's inventory guidance, not the policy.
5. **`agent-work <command> -h` prints the front controller's usage**, not the wrapped
   script's. That cost lookups. The fix is to forward `-h` in `scripts/agent-work`.
6. **§7's publication route cannot reset cadence.** Reports publish on staging, but the
   audited snapshot is integration, and `audit_cadence.py` needs the audited commit to
   be an ancestor of the HEAD that holds the rollup. The two requirements never meet
   until a release is accepted. The report branch cannot simply merge into integration,
   because it is cut from staging and would carry staging-line commits backward. §7
   should name the integration route for reports (a branch from integration carrying
   the report files), or the reporter should accept an audited commit reachable from
   `origin/agent/integration`.

## 10. Audit disposition

All five pillar reports and this rollup are complete and scored. The audit is
read-only, and its reports publish through the staging route. `FULL-AUDIT-2026-09-14`
closes once the six `AUDIT-*-2026-09-14` rows and the reopened
`NODE-TEST-DISCOVERY-2026-09-12` are on the docs line and `check_tasks.py` validates.

*Corrected 2026-09-14 at publication:* the draft said the metadata lines reset
`audit_cadence.py`. On engine `agent/staging-area` they do not. The reporter requires
the audited commit to be an ancestor of HEAD, and `ad2e6be7` is on `agent/integration`,
which does not carry this rollup, so it reports `unknown` on both lines. It resolves
when the rollup reaches `agent/integration`, or when an accepted release carries
`ad2e6be7` into staging. See §9 item 6.

*Corrected 2026-09-15:* §7 now publishes reports on both lines (row AUDIT-CADENCE-ROUTE-2026-09-14).
This rollup and the five pillar reports are on `agent/integration`, where the reporter counts
from `ad2e6be7`. Staging still reads `unknown` until an accepted release carries that commit.
