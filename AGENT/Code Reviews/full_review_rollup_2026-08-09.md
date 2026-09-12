---
Role: dated
---

# Full Project Audit — Rollup (2026-08-09)

> Full five-pillar, document-only audit under `AGENT/Review Procedures/`.

**Overall health:** 6/10

## 1. Snapshot

| | |
|---|---|
| Branch / audited commit | `agent/integration` @ `41c0e5fc1116a9a01aed3afc48dbc92f021d018d` |
| Audit branch | `agent/from-integration/full-audit-2026-08` |
| Working tree at pin | clean |
| `check_docs.py` | PASS, 43/43 |
| `run_tests.sh` | PASS, 135/135 suites |
| GDScript style | PASS, 313 tracked files |
| Analyzer | PASS, 12/12 |
| Infrastructure tests | PASS when invoked directly, 23/23; not in a required gate |
| Browser shell | PASS when invoked directly, 28/28; not in a required gate |
| Export smoke | Windows and Web debug exports PASS |
| Frozen release candidate | `agent/playtest-release-v0.7.1` @ `0db30fd17adb83fb7e912c57b7630933c31588d6` |

Pillar reports:

- [Code](code_review_2026-08-09.md)
- [Documentation](../Docs/documentation_review_2026-08-09.md)
- [Scenes, Data & Assets](data_assets_review_2026-08-09.md)
- [Tests, CI & Build](tests_ci_build_review_2026-08-09.md)
- [Process & History](process_history_review_2026-08-09.md)

## 2. Scorecard

| Pillar | Score | Delta vs 2026-07-15 |
|---|:---:|---|
| 1 — Code | 6/10 | unchanged; two outer transaction failures affect v0.7.1 |
| 2 — Documentation | 6/10 | unchanged; two shipped-behavior claims overstate known failures |
| 3 — Scenes/Data/Assets | 10/10 | unchanged; no actionable defect |
| 4 — Tests/CI/Build | 8/10 | unchanged; broader green coverage, but 51 assertions are ungated |
| 5 — Process/History | 7/10 | down 1; DoD pairing, note indexing, and claim liveness regressed |
| Overall health | 6/10 | unchanged weakest-pillar headline; rounded mean 7/10 (7.4, down from 7.6) |

## 3. Executive summary

Project health remains 6/10: the engine has materially stronger registries, content
isolation, formatting gates, exports, and 135 green suites, while the complete
scenes/data/assets pillar remains exemplary. The most important concern is a repeated
boundary pattern: validation succeeds inside one component but the player-facing
operation crosses a later consumer or rollback boundary without remaining atomic.
That pattern produces the two new v0.7.1 intake items—campaign resume and user-data
migration—and also explains why the returned pack-discovery failure escaped earlier
fixture coverage. Process health slipped slightly because several safeguards still
depend on manual audits rather than required gates.

## 4. Cross-pillar findings

### CROSS-1 — Player-facing transactions stop one boundary too early

**Owner:** Code. **Supporting pillars:** Documentation, Process/History, Tests.

The Code pillar proves that package activation can commit before campaign-resume
validation finishes, and that user-data migration can commit its permanent marker
after a partial copy. The Documentation pillar independently finds that the GDD states
the inner `CampaignManager` guarantee as though it covered the outer Continue/Load
flow. Process history connects this to earlier adapter/occupancy and skill-reference
incidents: focused tests stopped before the final consumer or rollback boundary.

These are two implementation tasks, not one patch. The shared remediation rule is to
test `activate -> final consumer -> injected failure -> complete rollback` for every
multi-owner transaction. Documentation corrections ship with their respective code
fixes under DoD#1.

### CROSS-2 — Native behavior cannot be promoted from headless intent

**Owner:** Documentation. **Supporting pillars:** Code and Process/History.

The live New Game catalogue says native FileDialog Escape behavior is implemented,
while repeated Windows returns—including v0.7.1—show the first Escape closes the
dialog and no ownership telemetry fires. This is already owned by
`IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`; the approved remediation replaces
filename editing inside FileDialog with a game-owned modal and leaves FileDialog to
choose only a location. The audit adds no duplicate blocker, but the GDD must carry a
Known issue until native acceptance passes.

### CROSS-3 — Mechanical process rules lack discovery and liveness gates

**Owner:** Process/History. **Supporting pillars:** Tests and Documentation.

Twenty-three infrastructure tests and 28 browser assertions pass but no required gate
discovers them. Four live session notes are absent from the index, 82 of 143 path claims
needed manual removal, and DoD#1 pairing still recurs as a review finding. One tooling
programme should add test discovery, claim-liveness/status checks, note/index
bijection, and non-blocking DoD#1/cadence reports rather than adding isolated prose.

### CROSS-4 — OPEN-11 and the documentation lifecycle authority are stale

**Owner:** Documentation.

`OPEN-11` still says UI scale is a future trigger after scale controls landed, and the
active lifecycle document still teaches the pre-typed `AGENT/Docs/` layout. These are
integration-only authority repairs. The lifecycle rewrite should land with a narrow
check against obsolete flattened paths; OPEN-11 should be reconciled to its delivered
state or remaining responsive scope.

## 5. Unified prioritized action plan

| Priority | Action | Impact / effort | Tracker disposition |
|---:|---|---|---|
| 1 | Repair pack discovery against a real exported fixture, proving install -> discovery -> selection before changing the export boundary. | Release blocker / small-medium | New v0.7.1 remediation row |
| 2 | Make package-backed campaign resume one transaction, or restore the complete prior `ContentSession` on every late rejection; add package identity, registry, catalogue and campaign-position rollback assertions. | High / medium | New v0.7.1 remediation row |
| 3 | Make user-data migration retryable and transactional; never write the global marker after any copy failure; inject a nested-write failure in tests. | High / medium | New v0.7.1 remediation row |
| 4 | Execute the approved game-owned filename-modal redesign and mark native FileDialog Escape Known issue until Windows acceptance passes. | Returned blocker / medium | Existing `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` |
| 5 | After the replacement pack passes its full lifecycle/export audit, remove every `res://data` compatibility source and prove a packless build offers no playable content. | Returned blocker / large | Existing `IMPL-ZERO-CONTENT-EXPORT-GATE` |
| 6 | Put infrastructure and browser suites behind one required discovery gate shared by hooks/CI/full checks. | Medium / small | New audit follow-up row |
| 7 | Retire the unsafe inventory converter or replace it with an explicit-root, dry-run-first, tested CLI. | Medium / small | New audit follow-up row |
| 8 | Correct the resume/FileDialog GDD clauses with their fixes; rewrite or retire the lifecycle authority and reconcile OPEN-11, adding narrow mechanical guards where ratified. | High authority risk / small | New documentation follow-up row plus code-task DoD#1 |
| 9 | Add claim-liveness, session-note bijection, DoD#1 changed-path, and audit-cadence reporting to the control plane. | Medium / medium | New process-tooling programme row |

The order deliberately separates discovery repair from zero-content removal. Removing
the compatibility catalogue before an exported replacement pack completes its real
lifecycle would convert the returned discovery defect into a build with no playable
path. Priorities 1–5 form the combined audit/v0.7.1 remediation programme; priorities
6–9 are integration/systemic work and do not justify modifying the frozen candidate.

## 6. v0.7.1 intake

Only these verified candidate-affecting items enter the release remediation intake:

1. **Pack discovery:** `CampaignPackRegistry._discover_candidate` iterates the
   registered map-registry envelope instead of normalized `entries`, then calls `get`
   on a `String`. Repair it and prove the complete exported-fixture lifecycle.
2. **Campaign resume atomicity:** package activation can survive a later resume
   rejection. Preserve the entire prior session on failure.
3. **User-data migration atomicity:** a partial copy can write the permanent marker and
   suppress all future retries.
4. **FileDialog text entry:** link, do not duplicate,
   `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` and its approved game-owned filename
   modal redesign.
5. **Zero-content boundary:** link, do not duplicate,
   `IMPL-ZERO-CONTENT-EXPORT-GATE`; execute only after item 1 proves the replacement
   pack lifecycle.

The documentation findings for resume and FileDialog are acceptance work inside those
implementation rows, not separate release blockers. Scenes/assets, ungated passing
tests, the stale converter, lifecycle prose, and process tooling do not affect the
candidate executable.

## 7. Process and tooling recommendations

- Discover checked-in infrastructure/browser test files from a single required runner.
- Reject path reservations by unstarted rows and report nonexistent or unreachable
  claimed paths before work begins.
- Verify every live root session note has exactly one index row, including notes
  introduced by merges.
- Report runtime changes lacking both a numbered GDD and roadmap update, allowing an
  explicit no-behavior-change justification.
- Add a low-noise days/commits-since-rollup notice to status/closeout.
- Update the review procedures: gdtoolkit is landed; analyzer tests are stdlib-capable;
  Docker availability and risk-based sampling need explicit treatment.

## 8. Regression watch

- **Campaign resume rollback:** recurring from the 2026-07-15 audit; the inner restore
  transaction improved, but the outer package + campaign boundary remains open.
- **DoD#1 pairing:** recurring from July; later closeout documentation still substitutes
  for the required same-change GDD/roadmap update.
- **Session-note indexing:** regressed from July's measured complete set to four missing
  rows.
- **Audit cadence:** regressed materially; this audit began 702 commits beyond the prior
  rollup despite the earlier recommendation for automated reminders.
- **Hook/CI analyzer and scene-integrity parity:** remains fixed.
- **GDScript formatting/lint gate:** now landed and green; remove it from the procedure's
  remaining backlog.
- **UID/import/scene integrity and root-tools export exclusion:** remain fixed.

## 9. Audit disposition

All five pillar reports and this rollup are complete. The audit branch remains a
document-only evidence branch; no remediation is implemented here. The audit closes
only after the canonical tracker contains the five v0.7.1 intake links/items and the
four systemic follow-ups, and after the generated active-work view validates.
