# Process/History Tooling Review — 2026-07-17

> **Status:** Proposed — discussion document only; no script, workflow, or policy changes were made.
> **Scope:** workspace workflow rules, `AGENT/Review Procedures/05_Process_History_Pillar.md`, recent project history, and `/workspace/godot-prometheus-env/scripts/`.
> **Snapshot:** `7861e38078c473209f3d03b33b67a27a65a43a54` on `agent/codex/2026-07-16/recover-stale-main-ai-scorer`.
> **Working tree:** already dirty before this review (five playtest/GDD files, `CLAUDE.md`, and untracked `builds/`). Those files were not modified.

## Executive summary

The project has strong human-readable history practices, but the workspace tools do not yet make the documented safe path the easiest path. The highest-value change is a small, tested workflow driver that composes start, check, commit, handoff, and close operations while recording machine-readable evidence. It should reuse the current scripts rather than replace them wholesale.

Three reliability gaps deserve attention first:

1. `agent-commit.sh` stages the entire worktree, which can silently absorb unrelated or pre-existing edits.
2. The commit and push helpers do not enforce the tests or AI trailers required by `repo/AGENTS.md`.
3. The launcher prints an instruction to register active work, but no script performs or validates that registration.

The current scripts pass `bash -n`; `repoctl.py` passes `py_compile`; ShellCheck found only integration/annotation warnings. The concern is workflow semantics and missing regression coverage, not basic syntax quality.

**Recommendation:** approve a narrow Phase 1 safety pass before any larger audit/report automation. Do not begin with a monolithic rewrite.

## Review sample

- Rules: `repo/AGENTS.md`, `Project_Prometheus/AGENTS.md`, Master Review Procedure, and Process & History Pillar.
- Scripts: `repoctl.py`, `lib/repo-common.sh`, task start/commit/push, manual-PR preparation, checkout/clone, and fast/full check wrappers.
- Recent history: latest 30 commits; full notes for 2026-06-15, 2026-06-14k, and 2026-06-14j; INDEX breadth check; prior process-history and procedure meta-reviews.
- Corpus checks: 100 session-note files and 100 INDEX links, with no missing or dead links.
- Commit-size sample: latest 80 commits; median 71 changed lines, 90th percentile 393, maximum 1,674. This supports adding a warning for oversized commits, not a hard size gate.

## Findings

### [High] PH-1 — `agent-commit.sh` can commit unrelated work

**Evidence:** `agent-commit.sh:26-27` shows status and then runs `git add -A`. The current checkout demonstrates the risk: it contained unrelated modified files and an untracked build directory before this review. The workspace rule asks for small logical commits (`repo/AGENTS.md:89-94`), but the helper's default stages every change.

**Impact:** a safe-looking helper can mix another agent's work, generated builds, or unrelated user edits into a commit. The secret-name block does not address scope.

**Recommendation:** make explicit paths the normal interface:

```text
agent-commit.sh --repo NAME --message MSG -- path/to/a path/to/b
```

- Refuse an empty path list unless `--all` is explicitly supplied.
- Show the staged name/status and diffstat, then require `--yes` in non-interactive automation.
- Reject tracked or untracked paths outside the repo and preserve pre-staged user changes unless explicitly selected.
- Warn, rather than fail, above configurable diff thresholds (for example 400 lines or 25 files).

**Effort:** Small–Medium (3–5 hours including tests).

### [High] PH-2 — required checks and attribution are prose-only in the helper path

**Evidence:** policy requires fast checks before commit and full checks before push/PR (`repo/AGENTS.md:89-94`) plus four AI metadata trailers (`repo/AGENTS.md:55-64`). `agent-commit.sh:37` creates a message-only commit; `agent-push.sh:29` pushes immediately. Neither records or verifies a check result. Recent history shows the team usually runs gates manually, but the 2026-06-14j note also records a non-executable hook, showing why hook-only enforcement is insufficient.

**Impact:** compliance depends on memory. Handoffs cannot prove which SHA was tested, and commits made through the official helper omit required provenance.

**Recommendation:** add a reusable `agent-check.sh` that writes a local, gitignored receipt keyed by repo, HEAD/tree hash, command, start/end time, and exit code. Then:

- `agent-commit.sh` runs fast checks by default and appends validated `AI-Tool`, `AI-Model`, `AI-Run-ID`, and `AI-Workspace` trailers.
- `agent-push.sh` requires a successful full-check receipt for the exact HEAD, with an explicit `--skip-checks --reason ...` escape hatch recorded in output.
- `prepare-manual-pr.sh` embeds the receipt rather than a blank “Tests” prompt.

Do not store secrets, environment dumps, or raw tokens in receipts.

**Effort:** Medium (1 day).

### [High] PH-3 — active-work coordination is declared but not implemented

**Evidence:** `repoctl.py:95,105` exports `COORDINATION_BRANCH`; policy says that branch owns the active-work registry (`repo/AGENTS.md:28-34`). `agent-start-task.sh:80-82` only prints “Register ... before implementation.” No workspace script reads, writes, or validates that registry.

**Impact:** two agents can begin overlapping work despite following the launcher. The exact metadata needed for coordination is produced, then discarded.

**Recommendation:** first define a small registry schema and concurrency behavior; then add `agent-work register|list|close|prune`. A record should include repo, branch, base branch/SHA, task slug, tool, run ID, paths/area, created time, and status. Registration should detect overlapping path claims and stale branches. Because this mutates a shared remote branch, design it as fetch → validate → commit → push with retry on non-fast-forward, never force-push.

**Effort:** Medium–Large (1–2 days). **Decision required:** whether registry updates may be automatic or must remain human-approved.

### [Medium] PH-4 — manual PR preparation can produce plausible but stale/incomplete evidence

**Evidence:** `prepare-manual-pr.sh:38` limits output to 20 commits and silently falls back to an unrelated log if `origin/$TARGET_BRANCH` is unavailable. Lines 43-44 similarly fall back to `HEAD~1..HEAD`; line 57 overwrites the same output on every run. It does not require an agent branch, fetch the target, check a clean tree, run full tests, report ahead/behind state, or validate commit trailers.

**Impact:** the generated document can omit commits and changed files while still looking valid.

**Recommendation:** fail closed when the target ref is absent; fetch first; use `merge-base...HEAD`; include the complete commit count plus a bounded display; add dirty/ahead/behind/trailer/check-receipt sections; and use a timestamp or SHA in the filename. Provide `--json` alongside Markdown so later tooling need not parse prose.

**Effort:** Small–Medium (4–6 hours).

### [Medium] PH-5 — the workspace automation itself has no versioned history or test suite

**Evidence:** `/workspace/godot-prometheus-env` is not a Git repository, so changes to `scripts/`, `repos.yaml`, and their rules have no local commit/blame/revert trail. The scripts tree has 45 files including Windows `Zone.Identifier` artifacts, and no dedicated tests for `repoctl.py` or the shell workflow. Syntax checks pass, but behavioral regressions—dirty-tree handling, ref collisions, staged scope, missing remotes—are untested.

**Impact:** the tools intended to improve history reliability are themselves outside that history and are risky to evolve.

**Recommendation:** version the environment tooling in its own repository (preferred) or a clearly owned tools directory/submodule. Add:

- stdlib `unittest` coverage for manifest normalization, defaults, validation, and emitted values;
- shell integration tests using temporary bare remotes and disposable worktrees;
- `bash -n`, ShellCheck, and tests as one `scripts/test-tools.sh` command;
- cleanup/ignore rules for `*:Zone.Identifier` and `__pycache__`.

**Effort:** Medium (1 day initial setup, then incremental tests).

### [Medium] PH-6 — `repos.yaml` is permissive enough to hide configuration mistakes

**Evidence:** `repoctl.py:81-115` supplies many silent defaults but performs no schema validation for branch relationships, repo kind spelling, command types, path containment, or required URLs. The manifest currently contains `campaign_data_pack` and `campaign_Data_pack`, demonstrating type drift.

**Impact:** misspellings become accepted configuration and downstream tools must guess semantics. A malicious or accidental path could resolve outside the intended workspace.

**Recommendation:** add `repoctl.py validate` and run it from health/setup commands. Validate unique names/paths, paths under the configured root unless explicitly allowed, known kinds, non-empty URLs, `agent/` branch policy, and scalar command fields. Print all validation errors in one pass.

**Effort:** Small (3–4 hours with tests).

### [Medium] PH-7 — session closure is auditable but unnecessarily manual

**Evidence:** the process requires a note plus newest-first INDEX row; the present corpus is excellent (100/100 bidirectional match). The latest notes follow a consistent What/Commits/State/Next structure, making safe scaffolding feasible.

**Impact:** discipline is strong today, but manual filename suffixing, commit lists, and INDEX insertion cost time and can degrade as contributors increase.

**Recommendation:** add `agent-session-note.sh` (or a Python subcommand) that:

- chooses the next collision-free date suffix;
- pre-fills branch, HEAD, commits since task base, tests from receipts, changed areas, and next-session placeholders;
- inserts the INDEX row atomically;
- validates note/index links without inventing narrative content.

Keep the summary and next-session plan human-authored.

**Effort:** Small–Medium (4–6 hours).

### [Medium] PH-8 — repeated history-review calculations should become a read-only tool

**Evidence:** the pillar repeatedly asks for session/index consistency, commit size, message quality, note/commit pairing, score trends, rework, and decision links. The prior review specifically reported fragile score extraction and slow manual traceability. This pass again needed custom commands to compute 100/100 note links and commit-size percentiles.

**Impact:** reviewers spend time rebuilding queries and may use different definitions between audits.

**Recommendation:** build `tools/history_audit.py` with deterministic, read-only subcommands and JSON/Markdown output:

- `notes` — orphan/dead-link/order/schema checks;
- `commits --since/--sample` — size percentiles, message heuristics, merge handling;
- `reviews` — anchored score extraction and trends;
- `decisions` — index schema, duplicate IDs, bidirectional supersession hints;
- `release` — version/tag/build-manifest cross-checks.

The tool should report evidence, not assign severity or decide whether behavior required a GDD update; those remain review judgments.

**Effort:** Medium–Large (1–2 days for a useful first version).

### [Low] PH-9 — argument and failure handling could be more uniform

**Evidence:** each shell script hand-rolls parsing. Missing values such as `--repo` at end of command can fail under `set -u` without a tailored message. `parse_repo_arg` triggered ShellCheck's cross-file SC2034 warning, and several scripts lack source annotations. Some helpers no-op when tests are unconfigured, which is appropriate for interactive setup but unsafe for a release/handoff gate.

**Recommendation:** centralize `require_arg_value`, common help formatting, and gate modes (`skip`, `warn`, `require`). Add `--quiet` and `--json` consistently only where machine consumption is useful.

**Effort:** Small (2–4 hours).

## Proposed target workflow

The fastest reliable flow is a thin orchestrator over independently usable primitives:

```text
agent-work start
  -> validate manifest/repo
  -> sync base and create branch
  -> register active work

agent-work check fast|full
  -> run configured commands
  -> write receipt bound to tree/HEAD

agent-work commit -- files...
  -> scope preview + secret/protected-path checks
  -> fast check
  -> commit with trailers

agent-work handoff
  -> full check for exact HEAD
  -> fetch target + compute complete merge-base diff
  -> generate Markdown + JSON handoff

agent-work close
  -> scaffold session note + INDEX row
  -> close coordination record
```

Each step must remain callable on its own. This avoids making recovery dependent on one stateful command.

## Complete script inventory review

The table below covers every substantive file in the top-level `scripts/` collection. `*:Zone.Identifier` files and `__pycache__` are accidental metadata/cache artifacts, not tools; they should be removed from the distributed collection and ignored at its versioned source.

| Script | Useful purpose? | Accuracy verdict | Recommendation |
|---|---|---|---|
| `repoctl.py` | **Yes — foundational.** Resolves the multi-repo manifest for every wrapper. | **Partial.** Quoting for shell output is careful, but the manifest is barely validated, requires undeclared PyYAML, permits kind spelling drift, and resolves paths outside the workspace. | **Keep and strengthen.** Make this the typed core: add `validate`, structured errors, known kinds, path policy, and unit tests. Prefer JSON as the internal interface; retain `env` for compatibility. |
| `lib/repo-common.sh` | **Yes — foundational.** Centralizes repo loading, branch checks, status, and authenticated Git. | **Mostly correct.** Askpass cleanup and credential-helper bypass are good. Argument parsing lacks missing-value checks; `git_auth` assumes askpass was initialized; `eval` is safe only as long as `repoctl.py env` remains correctly quoted. | **Keep.** Add argument helpers, command prerequisites, protected-path checks, check receipts, and integration tests. Reduce reliance on `eval` in the eventual Python core. |
| `list-repos.sh` | **Yes, but very thin.** Convenient discoverability. | **Correct** for listing manifest entries, but it does not show checkout/dirty/ahead-behind health. | **Keep** as an alias; add `--status` through `repoctl` rather than growing shell logic. |
| `clone-repo.sh` | **Yes.** Provides consistent authenticated cloning and active-branch setup. | **Mostly correct.** It safely avoids switching a dirty checkout. However, an existing non-Git directory is not diagnosed early, a dirty repo exits success despite skipping requested synchronization, and a missing active remote branch also exits success. | **Keep.** Add explicit result states and `--allow-dirty/--clone-only`; fail in strict/setup mode when synchronization was not completed. |
| `clone-all-repos.sh` | **Yes.** One-command workspace bootstrap. | **Mostly correct.** `pipefail` propagates failures, but it stops at the first failed repo and gives no final summary. | **Keep.** Attempt all repos, summarize pass/skip/fail, and return nonzero if any required operation failed. |
| `checkout-active-branch.sh` | **Yes.** Safely returns a repo to its configured stable branch. | **Mostly correct.** It fetches first and blocks dirty trees. When `origin/$ACTIVE_BRANCH` is absent it silently trusts a local branch, which may be stale or nonexistent. | **Keep.** Fail closed by default when the configured remote ref is absent; allow an explicit offline/local mode. Report resulting SHA and ahead/behind state. |
| `setup-project.sh` | **Yes in concept.** Intended as the reliable one-shot bootstrap. | **Incorrect success semantics.** Both import and fast-check failures are suppressed with `|| true`, so setup can exit 0 with a broken import or failing tests. It also inherits `clone-repo.sh`'s success-on-skip behavior. | **Fix first.** Required setup stages must fail the command. Optional stages need named flags such as `--skip-import` or `--skip-checks`, never unconditional suppression. Print a stage summary. |
| `health-check.sh` | **Yes.** Useful environment diagnosis without printing the token. | **Partial.** It labels misses but always exits successfully, does not validate `repos.yaml`, repo state, Docker/Compose, export templates, ShellCheck, or configured commands, and calls itself healthy even when required tools are absent. | **Keep and split modes.** `health-check --report` may always finish; `--strict` should return nonzero for requirements relevant to the selected repo/action. Run `repoctl validate`. |
| `agent-start-task.sh` | **Yes — core workflow.** Enforces clean start, synchronized base, safe branch prefix, and ref-prefix collisions. | **Mostly correct.** Its strongest script. Tool values are sanitized but not restricted to documented values; empty sanitized slugs/tools are possible; active-work registration is only printed, not performed. | **Keep.** Integrate registry registration, validate tool/slug, write local task metadata, and add rollback/clear guidance if registration fails after branch creation. |
| `agent-commit.sh` | **Yes — core workflow.** Intended to make commits comply with project rules. | **Unsafe/incomplete.** `git add -A` captures unrelated work; no fast-check enforcement; no required AI trailers; no protected-workflow approval check; secret matching is only filename-based and leaves staged changes behind after refusal. | **Fix first.** Explicit paths, scope preview, fast-check receipt, trailers, staged-state preservation, and tests. |
| `agent-push.sh` | **Yes — core workflow.** Protects branch namespace and uses safe authentication. | **Incomplete.** It does not require a clean tree, full tests, upstream/base sanity, required trailers, or a handoff artifact. Dry-run validates very little. | **Keep and strengthen.** Require exact-HEAD full-check evidence and validate commits. Keep push separate from PR creation and never force-push. |
| `prepare-manual-pr.sh` | **Yes.** A human-review handoff artifact fits the no-agent-merge policy. | **Potentially misleading.** It can use stale refs, truncates at 20 commits, falls back to unrelated ranges, overwrites output, and leaves tests/provenance blank. | **Keep after rewrite.** Fetch, fail closed, use merge-base, embed receipts/trailer audit, and emit Markdown plus JSON with SHA-stamped names. |
| `run-fast-checks.sh` | **Yes.** Stable manifest-driven check entry point. | **Correct for configured commands.** Treating an unconfigured command as successful skip is dangerous when called as a mandatory gate. `bash -lc` can introduce login-shell environment differences. | **Keep.** Add `--require-configured` (used by commit/setup), receipt output, timeout support, and direct argv-style commands in a future manifest schema. |
| `run-full-tests.sh` | **Yes.** Stable full-gate entry point. | **Same limitations as fast checks.** In the present manifest fast and full are identical, so the distinction provides no extra assurance for the main repo. | **Keep**, but define a genuinely broader full command or explicitly document that they are presently aliases. Add strict mode and receipts. |
| `godot-import-cache.sh` | **Yes.** Godot import/class-cache refresh is needed on setup and after asset changes. | **Incorrect success semantics.** `godot ... --editor || godot ... || true` returns success even if both attempts fail. It also lacks a timeout, log capture, and postcondition check. | **Fix first.** Try compatible modes deliberately, fail if all fail, cap runtime, retain a concise log, and verify expected cache/class artifacts. Non-Godot skip is appropriate. |
| `export-windows.sh` | **Yes.** Reproducible platform entry point. | **Functionally basic, release-incomplete.** It exports but does not require clean/tested source, check preset existence, prevent accidental overwrite, produce SHA/size/build stamp, or verify the artifact. | **Keep.** Factor three exporters through one tested `export-project` core; add release/non-release modes and an artifact manifest. |
| `export-linux-steamdeck.sh` | **Yes.** Linux/Steam Deck artifact generation. | **Same release gaps as Windows.** The name promises Steam Deck suitability but performs only the generic Linux preset export and no Deck-specific validation. | **Keep but rename or validate.** Use `export-linux.sh`, or add explicit Steam Deck architecture/input/aspect/smoke checks before retaining the stronger name. |
| `export-web.sh` | **Yes.** Web artifact generation. | **Same release gaps.** No post-export check that HTML/PCK/WASM outputs exist and are mutually consistent. | **Keep.** Use common exporter and validate the expected web artifact set. |
| `serve-web-local.sh` | **Yes.** Quick local web-export smoke testing. | **Default is inaccurate.** Web exports land in `builds/web/$REPO_NAME/`, while the server defaults to `builds/web`, commonly producing a directory listing rather than launching the game. It does not validate `index.html`, port availability, or bind policy. | **Fix.** Accept `--repo`, resolve the exact export directory, require `index.html`, and print LAN-binding implications if a non-loopback bind is later supported. |
| `enter-container.sh` | **Yes.** Convenience for host-side development. | **Mostly correct but context-dependent.** It assumes the caller is in the Compose project directory, Docker Compose exists, the service is running, and Bash is installed. | **Keep.** Resolve the compose file relative to `GODOT_ENV_ROOT`, validate service, and fall back to `sh` if needed. |
| `update-tools-build.sh` | **Yes, but privileged/rare.** Rebuilds the development tool image. | **Misaligned with documented reproducibility.** Defaults all tool versions to `latest` despite the guide describing pinned build arguments. It assumes the current directory contains Compose config and always forces `--no-cache`. | **Keep as maintainer-only.** Require explicit versions or read lock values; resolve compose path; offer `--no-cache`; print the resolved version set and resulting image ID. Changes remain approval-gated. |
| `README.md` | **Yes.** Entry-point documentation for the collection. | **Incomplete.** It documents only a small subset, omits failure/skip semantics and required workflow ordering, references `repos.yaml.example` which is not present in the observed root listing, and does not steer agents through the scripts strongly enough. | **Rewrite as generated/validated command catalog.** Include lifecycle flow, strictness, exit-code contract, examples, and the canonical “do not perform manually” mapping. |

### Consolidation verdict

No substantive script is wholly purposeless. The collection's problem is not bloat; it is that several thin scripts have inconsistent success semantics and duplicate parsing. Keep the user-facing command names for discoverability, but move logic into a tested core and make shell files compatibility wrappers. The three platform export scripts should share one implementation. Fast/full checks should share one runner. Agent task commands should share one workflow core.

## How to make future agents use the tools

Adoption needs both convenience and enforcement. Documentation alone is insufficient, while an MCP server alone cannot prevent an agent from invoking Git or Godot manually.

Recommended layers, in order:

1. **One canonical CLI:** `agent-work`/`repoctl` exposes start, status, check, commit, handoff, export, and close with machine-readable results. Existing scripts remain memorable aliases.
2. **Explicit agent policy:** add a short command mapping to the applicable `AGENTS.md`: “For these operations, use these commands; direct `git push`, `git commit`, release export, and branch creation require a stated reason.” Avoid duplicating detailed behavior in prose.
3. **Repository enforcement:** hooks and remote branch protection verify outcomes that matter—tests, trailers, protected paths, branch names, and release metadata. This catches manual bypass regardless of client.
4. **Startup discovery:** `agent-work status --agent` prints the active repo, permitted commands, task registration, dirty state, and exact next safe actions. Agent instructions should require it at task start.
5. **Receipts and clear errors:** tools should be faster than reconstructing commands, return JSON, and explain the recovery command when refusing an operation.
6. **Audit bypasses:** history tooling should report commits/pushes/releases lacking expected receipts or trailers. Escape hatches require `--reason`, so exceptions are visible rather than impossible.

### Is an MCP server the right tool?

**As the primary implementation: no. As a thin adapter over the canonical CLI/core: potentially yes.**

An MCP server would help agents discover capabilities and supply typed arguments. Useful read-only tools would include `workspace_status`, `list_repos`, `task_status`, `history_audit`, and `handoff_preview`. Mutating tools such as `start_task`, `run_checks`, `commit_selected`, and `prepare_handoff` could provide structured confirmation and results.

However, MCP has important limits:

- It cannot stop an agent or human from running raw shell/Git commands.
- It introduces another long-running process, protocol surface, configuration step, and version-compatibility burden.
- Git mutation, credentials, confirmation, streamed test output, and concurrent coordination are easier to test first in a normal CLI/library.
- Claude, Codex, humans, CI, and hooks all need the same behavior; only some of those consumers naturally speak MCP.

The recommended architecture is:

```text
tested Python workflow library
  -> canonical CLI (humans, shell agents, CI, hooks)
  -> thin shell compatibility wrappers
  -> optional MCP adapter (agent discovery and typed invocation)
```

Do not duplicate business rules inside the MCP server. It should call the same library or CLI, expose read-only tools first, and add mutations only after the CLI's safety and concurrency tests are mature.

**MCP decision gate:** build it only if agents repeatedly fail to discover or correctly parameterize the improved CLI after the AGENTS/startup changes. If that problem disappears, MCP would be extra maintenance without added enforcement.

## Recommended implementation order

| Phase | Change | Why first | Estimated effort |
|---|---|---|---|
| 1 | Version tools + add test harness; fix explicit commit scope; add manifest validation | Establishes a safe base and removes the largest data-mixing risk | 1–2 days |
| 2 | Check receipts, trailers, and fail-closed PR handoff | Enforces rules already ratified | 1 day |
| 3 | Session-note scaffolding and read-only history audit | Largest recurring time savings with low operational risk | 1–2 days |
| 4 | Coordination registry commands | Valuable, but shared-branch concurrency needs an explicit design decision | 1–2 days |
| 5 | Release/tag verifier | Fold in once build-stamp and manifest formats are confirmed | 0.5–1 day |

## Proposed acceptance criteria

- No workflow command stages a file unless the caller selected it or explicitly passed `--all`.
- A push/handoff cannot claim “tested” unless the receipt matches the exact HEAD/tree.
- Every helper-generated commit has the four required AI trailers and retains the human Git identity.
- Missing/stale target refs fail with a clear error; no `HEAD~1` evidence fallback.
- Temporary-repo tests cover dirty trees, existing refs/prefix collisions, missing remotes, failed checks, unrelated staged files, and concurrent registry updates.
- All commands avoid reading protected files and never print credentials.
- Existing standalone scripts remain compatible for at least one transition period.

## Positive observations

1. The manifest-driven design is a good foundation: repo-specific paths, branches, tests, and project kinds are already centralized.
2. Branch-prefix and ref-prefix collision checks in `agent-start-task.sh` are thoughtful and fail with actionable messages.
3. Git authentication is isolated through a temporary askpass helper and disables cached credential helpers.
4. Session history quality is excellent: all 100 note files are indexed with no broken reverse mapping.
5. Existing syntax quality is sound; the proposal is evolutionary, not a rescue rewrite.

## Decisions requested before implementation

1. Approve Phase 1 as the first change set?
2. Should fast checks run automatically on every helper commit, or may a valid recent receipt satisfy the gate?
3. Should active-work registration mutate `agent/coordination` automatically, or only generate a proposed registry patch for a human/agent to push?
4. Should environment tooling become its own repository, or live in an existing versioned repository?

## Changes deliberately not made

- No scripts, manifests, hooks, CI workflows, branches, tags, or coordination records were changed.
- No tests or exports were run; only read-only syntax/static checks and history queries were used.
- No pre-existing dirty files were staged or edited.
