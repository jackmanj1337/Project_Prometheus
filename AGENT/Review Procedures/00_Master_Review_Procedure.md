---
Role: topic
---

# Master Review Procedure — Full Project Audit

> **Status:** Active — orchestrator for the five-pillar project review
> **Last verified:** 2026-09-13
> **Corrected 2026-09-13:** Standardized bounded Luna workers with lead verification;
> replaced retired session-note duties, misleading coverage guarantees and edit-based
> cadence; pinned workspace evidence and consolidated baseline execution.

A full audit evaluates code, content, tests/builds, documentation and process against
the same declared evidence. It is a substantial review, not a per-commit diff check.
Assignment coverage is exhaustive; semantic review may be sampled. Always disclose
what was inspected, sampled, excluded or left unreviewed. A green test run or a path
assignment does not prove a subsystem correct.

## 1. Trigger, authority and scope

Run before a significant milestone, after a major refactor or painful playtest, or
when the advisory cadence reaches approximately four weeks or 30 commits. These are
prompts for lead judgment, not push gates. Record an agreed deferral in the existing
tracker row/standing handoff. Do not write a session note.

Use the applicable AGENTS.md and ratified decisions as authority; this procedure
does not expand permission to publish, rebuild containers, export releases, change
protected configuration or inspect secrets. Fixes are a separate implementation
pass. Historical work is judged against rules effective at that time.

Default scope is the workspace: Project_Prometheus, both campaign packs and the
container/tooling repository. The lead records any unavailable or excluded repository
and the resulting limitation. An engine-only audit must say so in its title and
cannot claim workspace coverage. Read the live tracker and standing handoff before
choosing scope; use scripts/agent-work --repo <name> status --agent for each repository.

## 2. Pillars and ownership

| Pillar | Procedure | Lead-authored report |
|---|---|---|
| 1 — Code | [Code procedure](01_Code_Pillar.md) | `AGENT/Code Reviews/code_review_YYYY-MM-DD.md` |
| 2 — Documentation | [Documentation procedure](02_Documentation_Pillar.md) | `AGENT/Docs/governance/documentation_review_YYYY-MM-DD.md` |
| 3 — Scenes, Data & Assets | [Content procedure](03_Scenes_Data_Assets_Pillar.md) | `AGENT/Code Reviews/data_assets_review_YYYY-MM-DD.md` |
| 4 — Tests, CI & Build | [Tests/build procedure](04_Tests_CI_Build_Pillar.md) | `AGENT/Code Reviews/tests_ci_build_review_YYYY-MM-DD.md` |
| 5 — Process & History | [Process procedure](05_Process_History_Pillar.md) | `AGENT/Code Reviews/process_history_review_YYYY-MM-DD.md` |

The following ordered rules are the engine repository's assignment map, consumed by
check_docs.py check 11. Patterns use Python fnmatchcase against repository-relative
POSIX paths (`*` also matches `/`); the **first matching rule owns the path**.
Specific rules precede broader directory rules. Protected names at any depth are
excluded by the checker before this map and must never be opened. No catch-all rule
may hide an unassigned top-level area. A rule assigns responsibility, not review credit.

<!-- BEGIN AUDIT COVERAGE -->
```json
[
  {"patterns": ["AGENT/Docs/*.py"], "pillar": 4},
  {"patterns": ["AGENT/GDD/*", "AGENT/Docs/*"], "pillar": 2},
  {"patterns": ["AGENT/Code Reviews/*", "AGENT/Review Procedures/*", "AGENT/Session Notes/*", "AGENT/Ledger/*", "AGENT/v0.5.4/*"], "pillar": 5},
  {"patterns": ["scripts/tests/*", "scripts/ci/*", "scripts/hooks/*", "scripts/*.sh"], "pillar": 4},
  {"patterns": ["scripts/*.uid"], "pillar": 3},
  {"patterns": ["scripts/*"], "pillar": 1},
  {"patterns": ["scenes/*", "data/*", "engine_data/*", "assets/*", "Draft UI assets/*", "default_bus_layout.tres"], "pillar": 3},
  {"patterns": ["test_fixtures/*", "tools/*", ".github/*"], "pillar": 4},
  {"patterns": ["AGENTS.md", "CLAUDE.md"], "pillar": 5},
  {"patterns": ["README.md"], "pillar": 2},
  {"patterns": [".dockerignore", ".gitattributes", ".gitignore", ".mailmap", ".mcp.json", "Dockerfile", "docker-compose.yml", "project.godot", "export_presets.cfg", "gdformatrc", "gdlintrc", "requirements-dev.txt", "run_tests.sh", "check_exported_registry_gate.sh", "test_exported_registry_gate.py"], "pillar": 4}
]
```
<!-- END AUDIT COVERAGE -->

For pack repositories, assign authored resources/media/manifests to 3, runtime
scripts to 1, test/validation scripts and configuration to 4, licensing/guides to 2,
and history/policy to 5. For the container, assign tools/scripts/hooks/tests/config
to 4, guides to 2, tracker/claims/memory/workflow history to 5. Record the resulting
path assignments in the rollup's coverage section; check 11 only validates the
engine map. Every included repository's tracked paths must be accounted for.

Inventory untracked and ignored areas by name without opening protected files.
Generated builds/, ui_previews/, import caches and frozen build checkouts are not
source-review coverage: record exclusions and select only explicitly relevant
artifact evidence. Engine content checks include all .tres/.tscn resources even
outside scenes/ or data/; the lead adds cross-pillar support where ownership is 1/4.

## 3. Shared prerequisites — lead runs once

1. Register the audit through scripts/agent-work add-task on the container docs line.
   One audit row may own all bounded worker assignments; any independent follow-up
   or deferred work must have a tracker row. Record the audit's reference and scope.
2. Pin branch, full commit SHA, tree state and purpose for **each** repository and
   authority ref. Confirm remote freshness through authenticated workflow helpers.
   Distinguish engine integration, accepted release and staging documentation; never
   silently substitute one for another. Record procedure revision separately from
   the code snapshot. A dirty snapshot needs an explicit patch identity or a clean
   isolated snapshot before reproducible execution can be claimed.
3. Probe actual Godot/Python/Node and optional analyzer/lint tools. Missing optional
   tooling is a limitation; it is not proof that CI is untested. Use the supported
   lowest-dependency invocation and read its actual CI/hook consumer.
4. Run configured checks through scripts/agent-work check once for each relevant
   snapshot. Include the engine docs check and full suite; reuse a valid exact-tree
   receipt if its logs cover the required evidence. Record command, cwd, SHA/tree,
   tool versions, exit code, elapsed time, pass/fail/skip counts and log paths. Check
   logs for runtime/script errors and missing summaries as well as exit status.
   Preserve the command's exit code before any output filtering. The engine runner
   handles its import pass; isolated runs must preserve that prerequisite.
5. A red baseline is evidence to classify, not automatically Critical. Distinguish
   broken behavior, harness failure, unavailable tools and mismatched sibling pack
   snapshots. Pass the actual result to every worker; never say “assume green”.
6. Inventory/assign paths and identify cross-system journeys: authored pack import
   and select_campaign(), editor authoring/export/reimport, save/load/migration,
   cancellation and rollback across the final consumer. Include both successful
   and rejected operations. Fixtures alone do not establish builder adoption.
7. Locate prior reports by pillar, including old documentation reports at the Docs
   root and archived/moved reports. Verify snapshot, scope and date in the report,
   not just lexicographic filename order. Supply confirmed paths and limitations.

Run stateful tests in an isolated checkout with isolated user data and pinned sibling
pack locations (the exact-tree runner supplies AGENT_SIBLING_REPO_ROOT). A Git
worktree alone does not isolate Godot user://, ports, exports or test output. Serialize
expensive/shared-state execution. Plain git log/blame and source reading need no
separate worktree when the lead guarantees the checkout remains pinned.

## 4. Standard execution — lead plus bounded Luna workers

The standard worker model is **gpt-5.6-luna**. The lead retains its assigned model
and owns baseline execution, scope, verification, cross-pillar reconciliation,
severity, scores, report writes and tracker updates. With four available agent
slots, use one lead plus at most three concurrent workers. Respect the actual slot
limit; queue assignments in waves. If Luna is unavailable, record the limitation
and use sequential lead review or an explicitly agreed substitute; do not silently
claim a different model is Luna.

Keep the five pillars as report ownership, not five enormous worker prompts. Split
code by subsystem/journey and documentation by authority cluster. Use a short first
assignment to calibrate evidence quality, then continue through the declared scope.
Default first wave: test/harness review, a critical code journey, and its authored
content/wiring. Follow with remaining subsystems, documentation and process history.
Never give every worker the full historical corpus or duplicate the baseline run.

Each worker brief must include:

- Model, pillar, concrete question and bounded path list; relevant pillar procedure
  plus this master as shared instructions (pass paths and a compact context packet).
- Immutable repository/authority/procedure SHAs, baseline evidence and known failures.
- Confirmed prior reports, applicable decisions and relevant existing task IDs.
- Allowed read-only commands, any explicitly delegated diagnostic execution, isolated
  output location if needed, and a time/tool budget chosen for the assignment.
- Required sample/coverage and return format below. Exhausting a budget means report
  unreviewed scope for reassignment; it never means mark the pillar complete.

Workers do not edit source, reports, policy or tracker, switch shared checkouts,
commit, push or launch builds. The lead may authorize a targeted reproduction in
an isolated environment when needed. Generic “follow the checklist” instructions
are not authorization for exports, container changes or expensive repeated suites.

Worker return (in the agent response, not a new document class):

1. Assignment ID, snapshot identities and inspected paths/behaviors; enumerate
   sampled, excluded and unreviewed scope with reasons.
2. Each candidate finding: local ID, title, proposed severity, confidence
   (confirmed / suspected), trigger and impact, repository@SHA:file:line evidence,
   contradictory source or reproduction where applicable, suggested remedy,
   cross-pillar owner and existing task ID (or “no match found”).
3. Commands run and observed results/log locations; separate observation from
   inference. “No finding” names the checks performed and proves no more than them.
4. Procedure friction, unresolved questions and recommended next bounded assignment.

The lead reproduces or independently checks consequential claims, rejects unsupported
ones and deduplicates shared root causes. A new audit snapshot is not a correction
to an old one; GDD paths are not automatically governed by every AGENT/Docs guard.
Check the actual policy predicate before reporting a conflict. Conflicting workers
or uncertain runtime semantics trigger focused investigation, not a majority vote.

## 5. Evidence and severity

| Severity | Impact bar |
|---|---|
| Critical | Demonstrated crash/data loss/security exposure, broken required gate, or live instruction that directs materially wrong work. |
| High | Correctness failure, serious measured performance issue, shipped doc/behavior mismatch, or missing protection on a critical path. |
| Medium | Maintainability debt, contributor-facing gap, rule drift or misleading coverage. |
| Low | Minor clarity, naming, style or cross-link defect. |

Every drift claim needs both the statement and its contradictory authority. Every
runtime claim needs a concrete trigger and inspected execution path or reproduction.
Do not promote “suspected” to a confirmed finding to fill a report. Planned decisions
are not implementation failures simply because delivery is still pending. Severity
follows demonstrated impact; confidence and coverage are separate dimensions.

## 6. Lead-authored reports and scores

Write five pillar reports and one AGENT/Code Reviews/full_review_rollup_YYYY-MM-DD.md
only after reconciling worker evidence. Each pillar includes scope/coverage, baseline
references, verified findings, useful positive observations, limitations and deltas
(new, fixed, regressed, newly scoped, not rechecked). Do not invent three positives
or a score when evidence is insufficient.

Scores are 1–10: 9–10 strong evidence with minor/no findings; 7–8 solid with bounded
issues; 5–6 notable debt; 3–4 serious failures; 1–2 broken critical capabilities.
Give the evidence-based rationale. Each scored pillar uses **Score:** N/10. The
rollup uses **Overall health:** N/10, the lowest pillar score, and shows the rounded
mean separately. Compare trends only for comparable scope. If any pillar remains
unreviewed/unscorable, mark the rollup draft/incomplete and omit the numeric overall
score; do not publish it under the completed full_review_rollup filename pattern.

Near the top of a completed rollup use these exact metadata lines, substituting the
actual audit date and primary engine snapshot (full SHA, without backticks):

```text
**Audit date:** YYYY-MM-DD
**Audited commit:** <40-hex primary repository SHA>
```

The date describes the audit, not the report's latest correction. Other repositories
and documentation/procedure authority SHAs belong in the snapshot table. Cadence
uses these fields; legacy reports use the filename date and first-add commit,
explicitly labelled as a fallback. Missing/malformed/unavailable evidence yields an
advisory unavailable result, not a fresh audit.

The rollup contains: snapshot/baseline table; five report links; coverage and omitted
scope; scorecard; concise executive assessment; deduplicated cross-pillar findings;
prioritized actions with task IDs/owners/dependencies; regression watch; procedure
friction and tooling recommendations. Prioritize impact and uncertainty before cheap
cosmetic wins. Keep native Windows acceptance distinct from headless/browser/container
rendering evidence; the latter does not independently authorize release promotion.

## 7. Closeout and maintenance

The lead uses scripts/agent-work for checks, commits, pushes and tracker operations.
Reports/procedure changes are infrastructure on the docs/staging route; any executed
checker change must also reach agent/integration. Product fixes follow the release
line separately. Respect applicable docs guards and use the existing logged mixed
change override only where it actually applies. Do not alter branch policy here.

Reuse existing tracker rows for findings already owned; create rows for new actionable
follow-ups. Use update-task --append-reference for evidence, with real dependencies
and triggers. Regenerate coordination/ACTIVE_WORK.md and validate coordination/tasks.json
through the existing tools on the docs line. Confirm the remote tracker state after
helper writes; a stale local copy is not evidence the update failed. No session notes.

Correct an existing report in place with a dated correction line. A genuinely new
audit at another snapshot gets a new dated report; use -b/-c suffixes for distinct
same-day runs only. Never create a second report merely to correct the first.

**One-in-one-out (2026-09-13):** this revision replaces the five unbounded pillar
dispatches with bounded Luna assignments, retires the substring-only check 11 in
favor of explicit path ownership, and replaces edit-based cadence in the existing
reporters. It adds no hook, tracker or report class. Future tooling proposals must
name what they retire, or explicitly justify why nothing can be retired. Prefer
repairing an existing checker over adding a gate. Workers recommend; a review alone
does not ratify a new policy or authorize implementation.

Known analyzer limitations must be verified against the pinned implementation before
use: array-valued resource parsing, dynamic/manifest references, orphan detection and
filenames containing spaces. Compare parser output with raw non-protected resources
or a focused Godot load before treating parser findings as product defects. Formatting
and analyzer tests already have gates; inspect their actual invocation instead of
recommending them again. Update these living procedures in place when friction is
confirmed, with a correction line and Last verified date.
